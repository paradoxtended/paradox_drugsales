local labels = {}

lib.callback('prp-drugsales:getItemLabels', false, function(data)
    labels = data
end)

local utils = {}

---@param coords vector3
---@param radius number
---@return CZone
function utils.createSellingZone(coords, radius)
    return lib.zones.sphere({
        coords = coords,
        radius = radius
    })
end

---@param coords vector3 | vector4
---@param data BlipData
---@return integer
function utils.createBlip(coords, data)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite(blip, data.sprite)
    SetBlipColour(blip, data.color)
    SetBlipScale(blip, data.scale)
    SetBlipDisplay(blip, 4)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.name)
    EndTextCommandSetBlipName(blip)

    return blip
end

---@param coords vector4 | vector3
---@param radius number
---@param color integer
---@return integer
function utils.createRadiusBlip(coords, radius, color)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, radius)

    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, radius)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    SetBlipAlpha(blip, 150)

    return blip
end

---@return boolean
function utils.isAllowed()
    for _, job in ipairs(Config.DisabledJobs) do
        if job == Framework.getJob() then
            return false
        end
    end

    return true
end

---@return boolean
function utils.hasDrug()
    for drug, _ in pairs(Config.Drugs) do
        if Framework.hasItem(drug) then
            return true
        end
    end

    return false
end

---@param zone? string
---@return string[]
function utils.getZonesDrugs(zone)
    local drugs = {}

    if not zone then
        for drug, data in pairs(Config.Drugs) do
            if not data.zones or #data.zones == 0 and Framework.hasItem(drug) then
                table.insert(drugs, drug)
            end
        end
    else
        for drug, data in pairs(Config.Drugs) do
            if data.zones then
                for _, zoneName in ipairs(data.zones) do
                    if zoneName == zone and Framework.hasItem(drug) then
                        table.insert(drugs, drug)
                    end
                end
            end
        end
    end

    return drugs
end

---@param name string
function utils.getItemLabel(name)
    return labels[name] or labels[name:upper()] or 'ITEM_NOT_FOUND'
end

---@param drugs string[]
---@return string
function utils.getRandomDrug(drugs)
    local index = math.random(1, #drugs)
    return drugs[index]
end

return utils