lib.locale()

local input

---@type { normal: integer, radius: integer }[], CZone[]
local blips, zones = {}, {}
---@type { index: string, locationIndex: integer }?
local currentZone

local utils = require 'client.utils'

for index, data in pairs(Config.SellingZones) do
    local radius = data.radius or Config.DefaultRadius

    for locationIndex, coords in ipairs(data.locations) do
        --- Create blips on resource start or player loaded
        local normal = utils.createBlip(coords, data.blip)
        local radiusBlip = utils.createRadiusBlip(coords, radius, data.blip.color)

        table.insert(blips, { normal = normal, radius = radiusBlip })

        --- Create zones, lib zones on resource start or player loaded
        local zone = utils.createSellingZone(coords, radius)

        --- Zone functions
        function zone:onEnter()
            if currentZone?.index == index and currentZone?.locationIndex == locationIndex then return end

            currentZone = { index = index, locationIndex = locationIndex }

            if data.message then
                Config.Notify(data.message.enter, 'inform')
            end
        end

        function zone:onExit()
            if currentZone?.index ~= index and currentZone?.locationIndex ~= locationIndex then return end

            currentZone = nil

            if data.message then
                Config.Notify(data.message.exit, 'inform')
            end
        end

        table.insert(zones, zone)
    end
end

---@param price number
---@param drug string
---@param entity integer Ped
local function sellDrug(price, drug, entity)
    --- todo finish this function and implement chance system (higher offer, lower chance)
end

---@param drug string
local function openDrugsale(drug)
    if input then return end
    input = promise.new()

    local data = Config.Drugs[drug]

    local label = utils.getItemLabel(drug)
    local amount = type(data.amount) == 'number' and data.amount or math.random(data.amount.min, data.amount.max)
    local price = { min = data.price.min, max = data.price.max }

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

---@param entity nmber
local function offerDrugs(entity)
    local drugs = utils.getZonesDrugs(currentZone?.index)

    if not drugs or #drugs < 1 then
        return Config.Notify(locale('nothing_to_offer'), 'error')
    end

    SetBlockingOfNonTemporaryEvents(entity, true)
    TaskTurnPedToFaceEntity(entity, cache.ped, -1)

    local success = Config.ProgressBar(locale('offering_drugs'), 5000, true, {
        dict = 'special_ped@bill@monologue_4@monologue_4g', clip = 'bill_ig_1_b_01_imofferingironclad_6'
    })

    if success then
        local drug = utils.getRandomDrug(drugs)
        local price = openDrugsale(drug)

        if price then
            sellDrug(drug, price, entity)
        else
            ClearPedTasks(entity)
        end
    end
end

exports.ox_target:addGlobalPed({
    label = locale('sell_drugs'),
    icon = 'fa-solid fa-joint',
    canInteract = function(_, distance)
        return utils.isAllowed() and utils.hasDrug() and distance <= 2.0
    end,
    onSelect = function(data)
        offerDrugs(data.entity)
    end
})

---@param data { sold: boolean, price: number }
RegisterNUICallback('closeDrugsale', function(data, cb)
    cb(1)
    SetNuiFocus(false, false)

    local promise = input
    input = nil

    promise:resolve(data.sold and data.price or nil)
end)