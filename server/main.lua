---@type table<integer, { drug: string, amount: number }>
local clients = {}

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

---@param netId number
---@param drugName string
---@param amount number
RegisterNetEvent('prp_drugsales:registerRobbery', function(netId, drugName, amount)
    local entity = NetworkGetEntityFromNetworkId(netId)

    if not entity then return end

    clients[netId] = {
        drug = drugName,
        amount = amount
    }

    TriggerClientEvent('prp_drugsales:robbedPlayer', -1, netId)
end)

---@param source number
---@param netId number
lib.callback.register('prp_drugsales:takeDrugs', function(source, netId)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    local client = clients[netId]

    -- If there is not client with netId then it's sure that this event has been triggered with executor (cheater executed it),
    -- or there is an option that players want to "fake it" by looting the same ped at the same time
    -- you can do whatever you want here (kick or ban player, it's up to you)
    if not client then
        -- YOUR CODE HERE
        return
    end

    clients[netId] = nil

    player:addItem(client.drug, client.amount)

    TriggerClientEvent('prp_drugsales:unregisterRobbery', -1, netId)

    return true
end)

---@param player Player
---@param drugName string
---@param amount number
local function refuseDeal(player, drugName, amount)
    TriggerClientEvent('prp-drugsales:notify', source, locale('client_refused'), 'error')
    
    local random = math.random(100)

    -- Client refuse and walk away
    if random < 33 then return end

    -- Client refuse and attack player
    if random > 33 and random < 66 then
        return TriggerClientEvent('prp_drugsales:attackPlayer', player.source)
    end

    -- Client refuse to pay and steal drug from player
    if random > 66 then
        player:removeItem(drugName, amount)
        return TriggerClientEvent('prp_drugsales:robPlayer', player.source, drugName, amount)
    end
end

---@param source number
---@param drugName string
---@param price number
---@param amount number
lib.callback.register('prp-drugsales:sell', function(source, drugName, price, amount)
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

    if math.random(1, 100) > acceptChance then
        addPlayerRep(player, -reputation.remove)
        refuseDeal(player, drugName, amount)

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
        Utils.logToDiscord(source, player, locale('webhook_sold', amount, Utils.getItemLabel(drugName), finalPrice, GetEntityCoords(GetPlayerPed(source))))
        player:addAccountMoney(account, finalPrice)
        player:removeItem(drugName, amount)

        return true 
    end

    return false
end)