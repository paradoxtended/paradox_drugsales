if Config.Wholesale.disabled then return end

---@type { normal: integer, radius: integer }[], CZone[]
local blips, zones = {}, {}
---@type { index: integer, locationIndex: integer }?
local currentZone

local function createWholesaleZones()
    for index, data in ipairs(Config.Wholesale.wholesaleZones) do
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

createWholesaleZones()

lib.callback.register('prp_drugsales:getWholesaleZone', function()
    return currentZone
end)