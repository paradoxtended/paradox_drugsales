if Config.Wholesale.disabled then return end

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

    return drugs
end

---@type table<integer, boolean>
local busy = {}

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

    local success = lib.callback.await('prp_drugsales:itemUsed', source, drugs)
    print(success)
end)