if Config.Wholesale.disabled then return end

---@type table<integer, { label: string, name: string, amount: number, price: number }[]>
local pending = {}

---@param player Player
---@param drug string[]
---@param data WholesaleZone
---@return { label: string, name: string, amount: number, price: number }[]
local function getRandomDrugs(player, drug, data)
    local drugs = {}

    for i = 1, #drug do
        if #drugs >= data.drugsVariety then break end

        local current = Config.Drugs[drug[i]]

        if current.wholesale and (math.random(100) <= current.wholesale.chance or i == #drug and #drugs == 0) and player:getItemCount(drug[i]) > 0 then
            table.insert(drugs, {
                label = Utils.getItemLabel(drug[i]),
                name = drug[i],
                amount = math.random(player:getItemCount(drug[i]) < current.wholesale.max and player:getItemCount(drug[i]) or current.wholesale.max),
                price = math.floor(math.random(current.price.min, current.price.max) / data.divisor)
            })
        end
    end

    pending[player.source] = drugs

    return drugs
end

---@type table<integer, boolean>
local busy = {}

---@param source number
---@param type 'confirmed' | 'negotiate' | false
---@param netId number?
lib.callback.register('prp_drugsales:finish', function(source, type, netId)
    local player = Framework.getPlayerFromId(source)

    if not player or player:getItemCount(Config.Wholesale.requiredItem) == 0 or not busy[source] then return end

    ---@type { index: integer, locationIndex: integer }?
    local currentZone = lib.callback.await('prp_drugsales:getWholesaleZone', source)

    if not currentZone then
        TriggerClientEvent('prp-drugsales:notify', source, locale('not_in_zone'), 'error')
        busy[source] = nil
        return
    end

    local data = Config.Wholesale.wholesaleZones[currentZone.index]
    local drugsList = currentZone and Config.Wholesale.wholesaleZones[currentZone.index]?.drugsList or Utils.getAllDrugs()

    if netId then
        local entity = NetworkGetEntityFromNetworkId(netId)
        
        if entity then
            SetTimeout(10000, function()
                DeleteEntity(entity)
            end)
        end
    end

    if type == 'negotiate' then
        return getRandomDrugs(player, drugsList, data)
    end

    if type == 'confirmed' and pending[source] then
        local items = pending[source]

        SetTimeout(1500, function()
            local webhook = { message = {}, total = 0 }

            for _, item in ipairs(items) do
                if player:getItemCount(item.name) < item.amount then return end
                
                player:removeItem(item.name, item.amount)
                player:addAccountMoney(data.account or Config.DefaultAccount, item.price * item.amount)

                table.insert(webhook.message, ('%sx %s for %s bills'):format(item.amount, item.label, item.price * item.amount))
                webhook.total += item.price * item.amount
            end

            Utils.logToDiscord(source, player, locale('webhook_wholesale_sold', table.concat(webhook.message, ', '), webhook.total, GetEntityCoords(GetPlayerPed(source))))
            if math.random(100) <= (data.dispatchChance or Config.DispatchData.Chance) then
                TriggerClientEvent('prp-drugsales:notify', source, locale('dispatched'), 'inform')
                Utils.dispatch(GetEntityCoords(GetPlayerPed(source)))
            end
        end)
    end

    pending[source] = nil
    busy[source] = nil

    return type ~= false
end)

Framework.registerUsableItem(Config.Wholesale.requiredItem, function(source)
    local player = Framework.getPlayerFromId(source)

    if not player or player:getItemCount(Config.Wholesale.requiredItem) == 0 or busy[source] then return end

    busy[source] = true

    ---@type { index: integer, locationIndex: integer }?
    local currentZone = lib.callback.await('prp_drugsales:getWholesaleZone', source)

    if not currentZone then
        TriggerClientEvent('prp-drugsales:notify', source, locale('not_in_zone'), 'error')
        busy[source] = nil
        return
    end

    -- Check if it's possible for the player to be in that zone
    local data = Config.Wholesale.wholesaleZones[currentZone.index]
    local coords = data.locations[currentZone.locationIndex]

    if #(GetEntityCoords(GetPlayerPed(source)) - coords) > (data.radius or 100.0) then
        busy[source] = nil
        return
    end

    local drugsList = currentZone and Config.Wholesale.wholesaleZones[currentZone.index]?.drugsList or Utils.getAllDrugs()
    local drugs = getRandomDrugs(player, drugsList, data)

    if #drugs < 1 then
        TriggerClientEvent('prp-drugsales:notify', source, locale('nothing_to_offer'), 'error')
        busy[source] = nil
        return
    end

    TriggerClientEvent('prp_drugsales:itemUsed', source, drugs)
end)