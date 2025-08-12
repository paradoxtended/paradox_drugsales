if Config.Hustling.disabled then return end

local Hustling = Config.Hustling

---@type table<integer, integer>
local activeLocations = {}

lib.addCommand(Hustling.command, {
    help = locale('hustle.command')
}, function(source)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    if player:hasOneOfJobs(Config.DisabledJobs) then
        TriggerClientEvent('prp-drugsales:notify', source, locale('is_cop'), 'error')
        return
    end

    if #activeLocations >= #Hustling.clients.locations then
        TriggerClientEvent('prp-drugsales:notify', source, locale('hustle.no_client_available'), 'error')
        return
    end

    local success = lib.callback.await('prp_drugsales:startHustle', source)

    if success then
        for i=0, 2000 do
            local location, locationIndex = Utils.randomFromTable(Hustling.clients.locations)

            if not activeLocations[locationIndex] then
                activeLocations[locationIndex] = source
                TriggerClientEvent('prp_drugsales:createHustleClient', source, location)

                return
            end
        end
    end
end)

---@param netId number
---@param door number
RegisterNetEvent('prp_drugsales:toggleEntityDoor', function(netId, door)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return end

    local owner = NetworkGetEntityOwner(entity)
    TriggerClientEvent('prp_drugsales:toggleEntityDoor', owner, netId, door)
end)

---@param source number
---@param netId number
lib.callback.register('prp_drugsales:getTrunkItems', function(source, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return end
    
    local plate = GetVehicleNumberPlateText(entity)
    local invId = 'trunk' .. plate
    return exports.ox_inventory:GetInventoryItems(invId)
end)