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

    -- Accept system
    local factor = price / drug.price.max
    -- Feel free to edit these numbers if you know what your are doing, but I think this is the golden mean
    local acceptChance = baseChance * (1.0 - (factor * 0.6))

    if math.random(1, 100) < acceptChance then
        TriggerClientEvent('prp-drugsales:notify', source, locale('client_refused'), 'error')

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

        player:addAccountMoney(account, finalPrice)
        player:removeItem(drugName, amount)

        return true 
    end

    return false
end)