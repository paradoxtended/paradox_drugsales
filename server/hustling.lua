if Config.Hustling.disabled then return end

---@class Items
---@field label string
---@field price number
---@field amount number
---@field name string

local Hustling = Config.Hustling

---@type table<integer, integer>
local activeLocations = {}
---@type table<string, integer>
local busy = {}
---@type table<integer, Items[]>
local pending = {}

lib.addCommand(Hustling.command, {
    help = locale('hustle.command')
}, function(source)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    if player:hasOneOfJobs(Config.DisabledJobs) then
        TriggerClientEvent('prp-drugsales:notify', source, locale('is_cop'), 'error')
        return
    end

    if busy[source] then
        local delay = Hustling.delay * 60000
        local timeSpent = GetGameTimer() - busy[source]
        local timeLeft = delay - timeSpent

        if timeLeft > 0 then
            local minutes = math.floor(timeLeft / 60000)
            local seconds = math.floor(timeLeft / 1000) % 60

            TriggerClientEvent('prp-drugsales:notify', source, locale('hustle.delay_message', ('%s minutes and %s seconds'):format(minutes, seconds)), 'error')
            return
        end

        busy[source] = nil
    end

    if #activeLocations >= #Hustling.clients.locations then
        TriggerClientEvent('prp-drugsales:notify', source, locale('hustle.no_client_available'), 'error')
        return
    end

    local success = lib.callback.await('prp_drugsales:startHustle', source)

    if success then
        for i=0, 2000 do
            local _, locationIndex = Utils.randomFromTable(Hustling.clients.locations)

            if not activeLocations[locationIndex] then
                busy[source] = GetGameTimer()
                activeLocations[locationIndex] = source
                TriggerClientEvent('prp_drugsales:createHustleClient', source, locationIndex)

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

---@param currentHustle { client: integer, index: numbers }
RegisterNetEvent('prp_drugsales:endHustle', function(currentHustle)
    local source = source
    local entity = NetworkGetEntityFromNetworkId(currentHustle.client)
    if not DoesEntityExist(entity) then return end

    -- If this condition will be true, then it is possible that this event has been triggered by cheater / exploiter
    if not activeLocations[currentHustle.index]
    or activeLocations[currentHustle.index] ~= source then
        -- YOUR CODE HERE
        return
    end

    activeLocations[currentHustle.index] = nil
    pending[source] = nil

    ClearPedTasks(entity)

    SetTimeout(10000, function()
        DeleteEntity(entity)
    end)
end)

---@param source number
---@param netId number
lib.callback.register('prp_drugsales:getTrunkItems', function(source, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if not DoesEntityExist(entity) then return end
    
    local plate = GetVehicleNumberPlateText(entity)
    local invId = 'trunk' .. plate
    local invItems = exports.ox_inventory:GetInventoryItems(invId)

    ---@type Items[]
    local items = {}

    for _, item in ipairs(invItems) do
        local drug = Config.Drugs[item.name]

        if drug and not drug.disableHustle then
            local price = math.floor(math.random(drug.price.min, drug.price.max) * Hustling.divider)
            local amount = item.count < Hustling.amount and math.random(item.count) or math.random(Hustling.amount)
            local label = item.label

            table.insert(items, { label = label, price = price, amount = amount, name = item.name })
        end
    end

    pending[source] = items

    return items
end)

---@param source number
---@param currentHustle { client: integer, vehicle: integer, index: number }
lib.callback.register('prp_drugsales:finishHustle', function(source, currentHustle)
    local player = Framework.getPlayerFromId(source)
    local coords = Hustling.clients.locations[currentHustle.index]
    local vehicle = NetworkGetEntityFromNetworkId(currentHustle.vehicle)

    if not player
    or not vehicle
    or not coords then
        return
    end

    -- Check if it's possible for player the bo in that zone
    if #(GetEntityCoords(GetPlayerPed(source)) - coords.xyz) > 100.0
    or activeLocations[currentHustle.index] ~= source then return end

    local plyItems = pending[source]
    local plate = GetVehicleNumberPlateText(vehicle)
    local invId = 'trunk' .. plate
    local reward = 0

    for _, item in ipairs(plyItems) do
        local success = exports.ox_inventory:RemoveItem(invId, item.name, item.amount)

        if success then
            reward += item.price * item.amount
        end
    end

    player:addAccountMoney(Hustling.account, reward or 1)

    return true
end)