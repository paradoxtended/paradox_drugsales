local reputation = 0.0

---@param rep number
local function updated(rep)
    if not rep then return end

    reputation = rep
end

lib.callback('prp_drugsales:getReputation', false, updated)

Framework.onPlayerLoaded(function()
    lib.callback('prp_drugsales:getReputation', 100, updated)
end)

RegisterNetEvent('prp_drugsales:updateReputation', updated)

---@return number
function getPlayerRep()
    return reputation
end