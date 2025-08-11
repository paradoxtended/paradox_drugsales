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

---@param data { sold: boolean, price: number }
RegisterNuiCallback('closeDrugsale', function(data, cb)
    cb(1)
    
    SetNuiFocus(false, false)

    local p = input
    input = nil

    p:resolve(data.sold and data.price or nil)
end)

---@param items { label: string, price: number, amount: number }[]
function waitForHustle(items)
    if input then return end
    input = promise.new()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'hustle',
        data = items
    })

    return Citizen.Await(input)
end

---@param result 'confirmed' | 'negotiate' | false
RegisterNuiCallback('hustle', function(result, cb)
    cb(1)

    SetNuiFocus(false, false)

    local p = input
    input = nil

    p:resolve(result)
end)