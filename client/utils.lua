lib.locale()

Utils = {}

---@generic K, V
---@param t table<K, V>
---@return V, K
---@diagnostic disable-next-line: duplicate-set-field
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
---@diagnostic disable-next-line: duplicate-set-field
function Utils.hasDrug()
    for drug, _ in pairs(Config.Drugs) do
        if Framework.hasItem(drug) then
            return true
        end
    end

    return false
end

---@param netId number Ped's netId
function Utils.attackPlayer(netId)
    local ped = NetworkGetEntityFromNetworkId(netId)

    if not ped then return end

    Config.Notify(locale('client_attacked'), 'inform')

    SetPedCombatAttributes(ped, 46, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedRelationshipGroupHash(ped, GetHashKey('AGGRESSIVE'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), GetHashKey('AGGRESSIVE'))
    SetRelationshipBetweenGroups(5, GetHashKey('AGGRESSIVE'), GetHashKey('PLAYER'))
    TaskCombatPed(ped, cache.ped, 0, 16)
    SetPedKeepTask(ped, true)
end

---@param netId number Ped's netId
---@param items { name: string, amount: number }[]
function Utils.robPlayer(netId, items)
    local ped = NetworkGetEntityFromNetworkId(netId)

    if not ped then return end

    Config.Notify(locale('client_stole'), 'inform')

    TaskSmartFleePed(ped, cache.ped, 50.0, -1, true, true)

    TriggerServerEvent('prp_drugsales:rob', netId, items)
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

---Create normal blip for entity
---@param entity number
---@param data BlipData
---@return integer
function Utils.createEntityBlip(entity, data)
    local blip = AddBlipForEntity(entity)

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

---Function returning distance between points. If distance is defined then it will return boolean
---@param point1 vector3 | vector4 | number
---@param point2 vector3 | vector4 | number
---@param distance number?
---@return boolean | number
function Utils.distanceCheck(point1, point2, distance)
    if type(point1) == 'number' then
        point1 = GetEntityCoords(point1)
    end

    if type(point2) == 'number' then
        point2 = GetEntityCoords(point2)
    end

    local dist = #(point1.xyz - point2.xyz)

    if distance then 
        return dist <= distance
    else 
        return dist 
    end
end

local labels = {}

lib.callback('prp-drugsales:getItemLabels', false, function(data)
    labels = data
end)

---@param name string
---@diagnostic disable-next-line: duplicate-set-field
function Utils.getItemLabel(name)
    return labels[name] or labels[name:upper()] or 'ITEM_NOT_FOUND'
end