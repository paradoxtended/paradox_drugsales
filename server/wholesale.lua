if Config.Hustling.disabled then return end

---@type table<integer, integer>
local activeLocations = {}

lib.addCommand(Config.Hustling.command, {
    help = locale('hustle.command')
}, function(source)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    if not Utils.hasDrug(player) then
        return TriggerClientEvent('prp-drugsales:notify', source, locale('no_drug'), 'error')
    end

    if player:hasOneOfJobs(Config.DisabledJobs) then
        return TriggerClientEvent('prp-drugsales:notify', source, locale('is_cop'), 'error')
    end

    if #activeLocations >= #Config.Hustling.clients.locations then
        return TriggerClientEvent('prp-drugsales:notify', source, locale('hustle.no_client_available'), 'error')
    end

    TriggerClientEvent('prp_drugsales:startHustle', source)
end)

lib.callback.register('prp_drugsales:getHustleClient', function(source)
    -- We are checking (2000 attempts) if there is some location available
    for _ = 0, 2000 do
        local location, locationIndex = Utils.randomFromTable(Config.Hustling.clients.locations)

        if not activeLocations[locationIndex] then
            activeLocations[locationIndex] = source
            return location, locationIndex
        end
    end

    return false
end)

lib.callback.register('prp_drugsales:getHustleItems', function(source)
    local player = Framework.getPlayerFromId(source)
    
    if not player then return end

    ---@type { label: string, amount: number, price: number }[]
    local items = {}

    for drugName, drug in pairs(Config.Drugs) do
        if player:hasItem(drugName) and not drug.disableHustle then
            table.insert(items, {
                label = Utils.getItemLabel(drugName),
                amount = math.random(player:getItemCount(drugName) <= Config.Hustling.hustling.amount and player:getItemCount(drugName) or Config.Hustling.hustling.amount),
                price = math.floor(math.random(drug.price.min, drug.price.max) * Config.Hustling.hustling.divider)
            })
        end
    end

    return items
end)

RegisterNetEvent('prp_drugsales:endHustle', function(locationIndex, netId)
    local source = source
    local entity = NetworkGetEntityFromNetworkId(netId)

    -- If this will return true, then we can tell that on 95% this event has been triggered by cheater / exploiter
    if activeLocations[locationIndex] ~= source then 
        -- YOUR CODE HERE
        return
    end

    activeLocations[locationIndex] = nil

    SetTimeout(15000, function()
        DeleteEntity(entity)
    end)
end)