if Config.Wholesale.disabled then return end

local GetScriptTaskStatus = GetScriptTaskStatus

---@type { normal: integer, radius: integer }[], CZone[], number
local blips, zones, attempt = {}, {}, 0
---@type { index: integer, locationIndex: integer }?
local currentZone

---@param level number
local function updateWholesaleZones(level)
    for index, data in ipairs(Config.Wholesale.wholesaleZones) do
        if data.minReputation and data.minReputation > level then return end
        for locationIndex, coords in ipairs(data.locations) do
            local zone = lib.zones.sphere({
                coords = coords,
                radius = data.radius or 100.0,
                onEnter = function()
                    if currentZone?.index == index and currentZone?.locationIndex == locationIndex then return end

                    currentZone = { index = index, locationIndex = locationIndex }

                    if data.message then
                        Config.Notify(data.message.enter, 'inform')
                    end
                end,
                onExit = function()
                    if currentZone?.index ~= index and currentZone?.locationIndex ~= locationIndex then return end

                    currentZone = nil

                    if data.message then
                        Config.Notify(data.message.exit, 'inform')
                    end
                end
            })

            table.insert(zones, zone)

            if data.blip then
                local normal = Utils.createBlip(coords, data.blip)
                local radius = Utils.createRadiusBlip(coords, data.radius or 100.0, data.blip.color)

                table.insert(blips, { normal = normal, radius = radius })
            end
        end
    end
end

---@param level integer
function UpdateWholesale(level)
    updateWholesaleZones(level)
end

local function createClient()
    local zone = Config.Wholesale.wholesaleZones[currentZone.index]
    local rawCoords = zone.locations[currentZone.locationIndex]
    local radius = zone.radius or 100.0
    local edit = vector3(rawCoords.x + math.random(-radius, radius), rawCoords.y + math.random(-radius, radius), rawCoords.z + 100.0)
    local hit, ground = GetGroundZFor_3dCoord(edit.x, edit.y, edit.z, false)

    local coords = vector3(edit.x, edit.y, hit and ground or rawCoords.z)
    local model = type(Config.Wholesale.client.models) == 'string' and Config.Wholesale.client.models or Utils.randomFromTable(Config.Wholesale.client.models)

    lib.requestModel(model)

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, 0.0, true, false)
    TaskGoToEntity(ped, cache.ped, -1, 5.0, 1.5, 1073741824, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)

    local blip = Utils.createEntityBlip(ped, Config.Wholesale.client.blip)

    return ped, blip
end

---Cannot do this with promises because player won't be able to use other item (weapon, food...)
---@param items { label: string, name: string, amount: number, price: number }[]
lib.callback.register('prp_drugsales:itemUsed', function(items)
    local zone = Config.Wholesale.wholesaleZones[currentZone.index]

    if not Config.ProgressBar(locale('searching_client'), 8000, true, {
        scenario = 'WORLD_HUMAN_STAND_MOBILE'
    }) then return end

    Config.Notify(locale('posted_announcement'), 'inform')

    local p = promise.new()

    CreateThread(function()
        Wait(math.random(zone.waitTime.min, zone.waitTime.max) * 1000)

        Config.Notify(locale('found_client'), 'inform')

        local ped, blip = createClient()

        while not Utils.distanceCheck(cache.ped, ped, 5.0) and not IsPedDeadOrDying(ped, false) do Wait(200) end
            
        if IsPedDeadOrDying(ped, false) then
            Config.Notify(locale('client_died'), 'error')
            return false
        end

        RemoveBlip(blip)

        local result = waitForHustle(items, attempt < Config.Wholesale.client.attempts)
        p:resolve(result)
    end)

    ---@todo fix this callback
    return Citizen.Await(p)
end)

lib.callback.register('prp_drugsales:getWholesaleZone', function()
    return currentZone
end)