Utils = {}

---@param coords vector3 | vector4
function Utils.dispatch(coords)
    local vector = vector3(coords.x, coords.y, coords.z)
    
    Dispatch.call(vector, Config.DispatchData, Config.PoliceJobs)
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