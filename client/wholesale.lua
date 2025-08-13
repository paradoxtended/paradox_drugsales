if Config.Wholesale.disabled then return end

---@type { normal: integer, radius: integer }[], CZone[], number
local blips, zones, attempt = {}, {}, 0
---@type { index: integer, locationIndex: integer }?, integer?
local currentZone, currentClient

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
    TaskGoToEntity(ped, cache.ped, -1, 3.0, 1.5, 1073741824, 0)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetModelAsNoLongerNeeded(model)

    local blip = Utils.createEntityBlip(ped, Config.Wholesale.client.blip)

    local p = promise.new()

    CreateThread(function()
        while not Utils.distanceCheck(cache.ped, ped, 3.0) and not IsPedDeadOrDying(ped, false) do Wait(500) end

        if IsPedDeadOrDying(ped, false) then
            Config.Notify(locale('client_died'), 'error')
        end

        RemoveBlip(blip)
        p:resolve(not IsPedDeadOrDying(ped, false) and ped or false)
    end)

    local client =  Citizen.Await(p)

    local target = GetEntityCoords(cache.ped)
    local coords = GetEntityCoords(ped)
    local clientHeading = GetHeadingFromVector_2d(target.x - coords.x, target.y - coords.y)
    local pedHeading = GetHeadingFromVector_2d(coords.x - target.x, coords.y - target.y)

    SetEntityHeading(ped, clientHeading)
    SetEntityHeading(cache.ped, pedHeading)

    currentClient = client
end

--- Feel free to edit this function if you don't like the animation when deal ends successfully
local function createSyncScene()
    local ped = currentClient

    local coords = GetEntityCoords(ped)
    local rotation = GetEntityRotation(ped)

    lib.requestAnimDict('mp_ped_interaction')

    local netScene = NetworkCreateSynchronisedScene(coords.x, coords.y, coords.z, rotation.x, rotation.y, rotation.z, 0, false, false, 1065353216, 0, 1.0)
    NetworkAddPedToSynchronisedScene(cache.ped, netScene, 'mp_ped_interaction', 'hugs_guy_b', 3.0, 3.0, 1, 16, 1148846080, 0)
    NetworkAddPedToSynchronisedScene(ped, netScene, 'mp_ped_interaction', 'hugs_guy_a', 3.0, 3.0, 1, 16, 1148846080, 0)

    NetworkStartSynchronisedScene(netScene)

    RemoveAnimDict('mp_ped_interaction')
end

---@param items { label: string, name: string, amount: number, price: number }[]
local function itemUsed(items)
    local zone = Config.Wholesale.wholesaleZones[currentZone.index]
    local coords = zone.locations[currentZone.locationIndex]

    if not Config.ProgressBar(locale('searching_client'), 8000, true, {
        scenario = 'WORLD_HUMAN_STAND_MOBILE'
    }) then return end
    Config.Notify(locale('posted_announcement'), 'inform')

    local p = promise.new()

    local interval = SetInterval(function()
        if not Utils.distanceCheck(cache.ped, coords, zone.radius or 100.0) then
            p:resolve(false)
        end
    end, 100) --[[@as number?]]

    local function wait(milliseconds)
        Wait(milliseconds)

        return p.state == 0
    end

    CreateThread(function()
        if not wait(math.random(zone.waitTime.min, zone.waitTime.max) * 1000) then return end

        Config.Notify(locale('found_client'), 'inform')

        if interval then
            ClearInterval(interval)
            interval = nil
        end

        createClient()

        lib.playAnim(currentClient, 'timetable@amanda@ig_2', 'ig_2_base_amanda', 3.0, 3.0, -1, 11)
        Config.ProgressBar(locale('introducing_yourself'), 3000, false, {
            dict = 'oddjobs@assassinate@vice@hooker',
            clip = 'argue_a',
            flag = 0
        })
        lib.playAnim(cache.ped, 'timetable@amanda@ig_2', 'ig_2_base_amanda', 3.0, 3.0, -1, 11)

        local result = currentClient and waitForHustle(items, attempt < Config.Wholesale.client.attempts)

        p:resolve(currentClient and result)
    end)

    local success = Citizen.Await(p)
    
    while success == 'negotiate' and attempt < Config.Wholesale.client.attempts do
        if not Config.ProgressBar(locale('renegotiating_deal'), 8000, true, {
            dict = 'oddjobs@assassinate@vice@hooker',
            clip = 'argue_a',
            flag = 0
        }) then
            success = false
            break
        end

        lib.playAnim(cache.ped, 'timetable@amanda@ig_2', 'ig_2_base_amanda', 3.0, 3.0, -1, 11)
        attempt += 1

        local items = lib.callback.await('prp_drugsales:finish', false, success)
        success = waitForHustle(items, attempt < Config.Wholesale.client.attempts)
    end

    local netId = NetworkGetNetworkIdFromEntity(currentClient)
    local success = lib.callback.await('prp_drugsales:finish', false, success, netId)

    if success then
        Config.Notify(locale('deal_success'), 'success')
        createSyncScene()
    end

    SetEntityAsNoLongerNeeded(currentClient)
    currentClient, attempt = nil, 0
end

RegisterNetEvent('prp_drugsales:itemUsed', itemUsed)

lib.callback.register('prp_drugsales:getWholesaleZone', function()
    return currentZone
end)