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