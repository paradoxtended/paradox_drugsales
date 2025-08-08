if Config.Wholesale.disabled then return end

---@type { normal: integer, radius: integer }, CZone[]
local blips, zones = {}, {}
---@type { index: integer, locationIndex: integer }?
local currentZone

local function createClient()
    ---@todo spawn a ped in radius and make him to come to player
end

local function waitForClient(zone)
    local p = promise.new()

    local interval = SetInterval(function()
        if not currentZone then
            p:resolve(false)
        end
    end, 100) --[[@as number?]]

    local function wait(milliseconds)
        Wait(milliseconds)

        return p.state == 0
    end

    CreateThread(function()
        if not wait(math.random(zone.waitTime.min, zone.waitTime.max) * 1000) then return end
        
        if interval then
            ClearInterval(interval)
            interval = nil
        end

        p:resolve(true)
    end)

    local success = Citizen.Await(p)

    if interval then
        ClearInterval(interval)
        interval = nil
    end

    return success
end

local function enterZone()
    local zone = Config.Wholesale.zones[currentZone.index]
    
    -- Check if player has one of the drugs from zone.drugs
    local drugName, amount = lib.callback.await('prp_drugsales:checkWholesale', false)

    if drugName and amount then
        local success = waitForClient(zone)
        
        if success then
            createClient()
        end
    else
        Config.Notify(locale('no_drugs_to_sell'), 'error')
    end
end

for index, data in ipairs(Config.Wholesale.zones) do
    for locationIndex, coords in ipairs(data.locations) do
        local zone = lib.zones.sphere({
            coords = coords,
            radius = data.radius or 100.0,
            onEnter = function()
                if currentZone?.index == index and currentZone?.locationIndex == locationIndex then return end

                currentZone = { index = index, locationIndex = locationIndex }
                
                CreateThread(function()
                    enterZone()
                end)

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

lib.callback.register('prp_drugsales:getWholesaleZone', function()
    return currentZone
end)