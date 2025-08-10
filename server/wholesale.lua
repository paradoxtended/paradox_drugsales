if Config.Wholesale.disabled then return end

lib.addCommand(Config.Wholesale.command, {
    help = locale('sell_command_help')
}, function(source)
    TriggerClientEvent('prp_drugsales:callDealers', source)
end)

lib.callback.register('prp_drugsales:checkWholesale', function(source)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    local currentZone = lib.callback.await('prp_drugsales:getWholesaleZone', source)

    if not currentZone then return end

    local zone = Config.Wholesale.zones[currentZone.index]
    
    ---@type { name: string, max: number }[]
    local drugs = {}

    for drugName, data in pairs(zone.drugs) do
        if player:getItemCount(drugName) >= data.amount.min then
            table.insert(drugs, { 
                name = drugName, 
                max = player:getItemCount(drugName) < data.amount.max and player:getItemCount(drugName) or data.amount.max
            })
        end
    end

    if #drugs > 0 then
        local randomDrug = Utils.randomFromTable(drugs)
        local data = zone.drugs[randomDrug.name]

        local amount = math.random(data.amount.min, randomDrug.max)

        return randomDrug.name, amount
    end

    return false
end)