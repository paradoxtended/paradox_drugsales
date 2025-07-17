lib.locale()

Utils = {}

---@generic K, V
---@param t table<K, V>
---@return V, K
function Utils.randomFromTable(t)
    if type(t) ~= 'table' then
        error("expected table, recieved: %s", type(t))
    end

    local index = math.random(1, #t)
    return t[index], index
end

---Check if player has one of the defined jobs
---@param jobs string | string[]
---@return boolean
function Utils.hasJob(jobs)
    if type(jobs) == 'string' then
        jobs = { jobs } ---@cast jobs string[]
    end

    for _, job in ipairs(jobs) do
        if job == Framework.getJob() then
            return true
        end
    end

    return false
end

---Check if player has any drugs with him
---@return boolean
function Utils.hasDrug()
    for drug, _ in pairs(Config.Drugs) do
        if Framework.hasItem(drug) then
            return true
        end
    end

    return false
end

---Create normal blip for coords
---@param coords vector3 | vector4
---@param data BlipData
---@return integer
function Utils.createBlip(coords, data)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

    SetBlipSprite (blip, data.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, data.scale)
    SetBlipColour(blip, data.color)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(data.name)
    EndTextCommandSetBlipName(blip)

    return blip
end

---Create radius blip for coords
---@param coords vector3 | vector4
---@param scale number
---@param color integer
---@return integer
function Utils.createRadiusBlip(coords, scale, color)
    local blip = AddBlipForRadius(coords.x, coords.y, coords.z, scale)

    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, scale)
    SetBlipColour(blip, color)
    SetBlipAsShortRange(blip, true)
    SetBlipAlpha(blip, 150)

    return blip
end

local labels = {}

lib.callback('prp-drugsales:getItemLabels', false, function(data)
    labels = data
end)

---@param name string
function Utils.getItemLabel(name)
    return labels[name] or labels[name:upper()] or 'ITEM_NOT_FOUND'
end