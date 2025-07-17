local input

---@param drugName string
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
            price = price
        }
    })

    return Citizen.Await(input)
end

---@param data { sold: boolean, price: number }
RegisterNuiCallback('closeDrugsale', function(data, cb)
    cb(1)
    SetNuiFocus(false, false)

    local p = input
    input = nil

    p:resolve(data.sold and data.price or nil)
end)