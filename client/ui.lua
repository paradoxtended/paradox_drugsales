local input

---@param drugName string
---@return number?, number?
function waitForPrice(drugName)
    if input then return end
    input = promise.new()

    local drug = Config.Drugs[drugName]
    local price = { min = drug.price.min, max = drug.price.max }
    local label = Utils.getItemLabel(drugName)
    local amount = lib.callback.await('prp-drugsales:getDrugAmount', false, drugName)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openDrugsale',
        data = {
            itemLabel = label,
            amount = amount,
            rep = getPlayerRep(),
            price = price
        }
    })

    return Citizen.Await(input), amount
end

---@param drugName string
---@param amount number
---@param price number
function waitForDecision(drugName, amount, price)
    if input then return end
    input = promise.new()

    local label = Utils.getItemLabel(drugName)

    SetNuiFocus(true, false)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({
        action = 'openBulkSale',
        data = {
            itemLabel = label,
            amount = amount,
            price = price
        }
    })

    return Citizen.Await(input)
end

---@param data { sold: boolean, price: number }
RegisterNuiCallback('closeDrugsale', function(data, cb)
    cb(1)
    
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    local p = input
    input = nil

    p:resolve(data.sold and data.price or nil)
end)