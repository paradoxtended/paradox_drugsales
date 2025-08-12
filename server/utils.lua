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

---@param coords vector3 | vector4
function Utils.dispatch(coords)
    local vector = vector3(coords.x, coords.y, coords.z)
    Dispatch.call(vector, Config.DispatchData, Config.PoliceJobs)
end

---@param source integer
---@param xPlayer Player 
---@param message string
function Utils.logToDiscord(source, xPlayer, message)
    if Config.Webhook == 'WEBHOOK_HERE' then return end

    local connect = {
        {
            ["color"] = "16768885",
            ["title"] = GetPlayerName(source) .. " (" .. xPlayer:getIdentifier() .. ")",
            ["description"] = message,
            ["footer"] = {
                ["text"] = os.date('%H:%M - %d. %m. %Y', os.time()),
                ["icon_url"] = 'https://i.postimg.cc/BnFQFgrd/PRP.png',
            },
        }
    }
    PerformHttpRequest(Config.Webhook, function(err, text, headers) end,
        'POST', json.encode({ username = resourceName, embeds = connect }), { ['Content-Type'] = 'application/json' })
end

---Check if player has any drugs with him
---@param player Player
---@return boolean
---@diagnostic disable-next-line: duplicate-set-field
function Utils.hasDrug(player)
    for drug, _ in pairs(Config.Drugs) do
        if player:hasItem(drug) then
            return true
        end
    end

    return false
end

---Helper function which is returning all drugs
---@return string[]
function Utils.getAllDrugs()
    local drugs = {}

    for drugName, _ in pairs(Config.Drugs) do
        table.insert(drugs, drugName)
    end

    return drugs
end

local labels, ready

CreateThread(function()
    while not labels do
        local items = Framework.getItems()
        local temp = {}

        for name, item in pairs(items) do
            temp[item.name or name] = item.label or 'NULL'
        end

        labels = temp

        Wait(100)
    end

    ready = true
end)

lib.callback.register('prp-drugsales:getItemLabels', function()
    while not ready do Wait(100) end

    return labels
end)

---@param name string
---@diagnostic disable-next-line: duplicate-set-field
function Utils.getItemLabel(name)
    return labels[name] or labels[name:upper()] or 'ITEM_NOT_FOUND'
end