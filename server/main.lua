---@type table<integer, { name: string, amount: number }[]>
local robberies = {}

---@param netId number
---@param items { name: string, amount: number }[]
RegisterNetEvent('prp_drugsales:rob', function(netId, items)
    local player = Framework.getPlayerFromId(source)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if not player or not entity or robberies[netId] then return end

    if type(items) ~= 'table' or table.type(items) ~= 'array' then items = { items } end
    
    robberies[netId] = {}

    for i = 1, #items do
        local option = items[i]

        player:removeItem(option.name, option.amount)
        robberies[netId][i] = { name = option.name, amount = option.amount }
    end

    TriggerClientEvent('prp_drugsales:registerRobbery', -1, netId)
end)

---@param source number
---@param netId number
lib.callback.register('prp_drugsales:robbery', function(source, netId)
    local player = Framework.getPlayerFromId(source)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if not player or not entity then return end

    -- Possible exploiter or cheater or 2 players are looting the ped
    if not robberies[netId] then
        -- YOUR CODE HERE
        return
    end

    if #(GetEntityCoords(GetPlayerPed(source)) - GetEntityCoords(entity)) > 3.0 then return end

    for _, item in ipairs(robberies[netId]) do
        player:addItem(item.name, item.amount)
    end

    robberies[netId] = nil
    TriggerClientEvent('prp_drugsales:unregisterRobbery', -1, netId)

    SetTimeout(10000, function()
        DeleteEntity(entity)
    end)

    return true
end)

---@param source number
---@param drugName string
lib.callback.register('prp-drugsales:getDrugAmount', function(source, drugName)
    local player = Framework.getPlayerFromId(source)
    local drug = Config.Drugs[drugName]

    if not player
    or not drug then 
        return
    end

    local plyAmount = player:getItemCount(drugName)
    local amount

    if type(drug.amount) == 'number' and drug.amount <= plyAmount then
        amount = drug.amount
    elseif drug.amount.min <= plyAmount and plyAmount <= drug.amount.max then
        amount = math.random(drug.amount.min, plyAmount)
    elseif drug.amount.min <= plyAmount and plyAmount > drug.amount.max then
        amount = math.random(drug.amount.min, drug.amount.max)
    else
        amount = 1
    end

    return amount
end)

---@param source number
---@param netId number
---@param items { name: string, amount: number }[]
local function refuseDeal(source, netId, items)
    TriggerClientEvent('prp-drugsales:notify', source, locale('client_refused'), 'error')
    
    local random = math.random(100)

    -- Client refuse and walk away
    if random < 33 then return end

    -- Client refuse and attack player
    if random > 33 and random < 66 then
        TriggerClientEvent('prp_drugsales:attack', source, netId)
        return
    end

    -- Client refuse to pay and steal drug from player
    if random > 66 then
        TriggerClientEvent('prp_drugsales:rob', source, netId, items)
        return
    end
end

---@param source number
---@param drugName string
---@param price number
---@param amount number
---@param netId number
lib.callback.register('prp-drugsales:sell', function(source, drugName, price, amount, netId)
    local player = Framework.getPlayerFromId(source)
    local drug = Config.Drugs[drugName]

    if not player
    or not drug
    or price > drug.price.max
    or price < drug.price.min
    or amount < drug.amount.min
    or amount > drug.amount.max then
        return
    end

    local account = Config.DefaultAccount
    local baseChance = Config.DefaultAcceptChance
    local dispatchChance = Config.DispatchData.Chance

    local currentZone = lib.callback.await('prp-drugsales:currentZone', source)

    if currentZone then
        -- Check if it's possible for the player to be in that zone
        local zone = Config.SellingZones[currentZone.index]
        local location = zone.locations[currentZone.locationIndex]
        local radius = zone.radius or Config.DefaultRadius

        if #(GetEntityCoords(GetPlayerPed(source)) - location.xyz) > radius then 
            return
        end

        -- Check if drugName is allowed to be sold in that zone
        if drug.zones and not lib.table.contains(drug.zones, currentZone.index) then
            return
        end

        account = zone.account or account
        baseChance = zone.acceptChance or baseChance
        dispatchChance = zone.dispatchChance or dispatchChance
    end

    -- Reputation
    local reputation = {
        add = drug.rep and (type(drug.rep) == 'number' and drug.rep or drug.rep.add) or Config.DefaultRep,
        remove = drug.rep and (type(drug.rep) == 'number' and drug.rep or drug.rep.remove) or Config.DefaultRep,
        current = getPlayerRep(player)
    }

    -- Accept system
    local factor = price / drug.price.max
    -- Feel free to edit these numbers if you know what your are doing, but I think this is the golden mean
    local base = baseChance * (1.0 - (factor * 0.6))
    -- We need to adjust accept chance with reputation because if player has 100 reputation then he'll be able to sell forever without chance to fail
    -- 10% is max to be addded to accept chance after clamp (0 - 10)
    local acceptChance = base + math.max(0, math.min(reputation.current, 10))

    if math.random(1, 100) <= acceptChance then
        addPlayerRep(player, -reputation.remove)
        refuseDeal(source, netId, { name = drugName, amount = amount })

        -- Dispatch police
        if math.random(1, 100) < dispatchChance then
            TriggerClientEvent('prp-drugsales:notify', source, locale('dispatched'), 'inform')
            Utils.dispatch(GetEntityCoords(GetPlayerPed(source)))
        end

        return
    end

    local progress = lib.callback.await('prp-drugsales:animation', source, drugName)

    if progress then
        -- Check if player still has drugs
        if player:getItemCount(drugName) < amount then return end

        local finalPrice = price * amount

        addPlayerRep(player, reputation.add)
        addPlayerDrug(player, drugName, amount)
        addPlayerEarnings(player, finalPrice)
        Utils.logToDiscord(source, player, locale('webhook_sold', amount, Utils.getItemLabel(drugName), finalPrice, GetEntityCoords(GetPlayerPed(source))))
        player:addAccountMoney(account, finalPrice)
        player:removeItem(drugName, amount)

        return true 
    end

    return false
end)