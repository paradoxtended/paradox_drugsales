-- Store NPCs so player won't be able to sell to one NPC forever
local cachedPeds = {}

exports.ox_target:addGlobalPed({
    label = locale('sell_drugs'),
    icon = 'fa-solid fa-joint',
    canInteract = function(entity, distance)
        return distance <= 2.0 and not Utils.hasJob(Config.DisabledJobs) and Utils.hasDrug() and not cachedPeds[entity]
    end,
    onSelect = function(data)
        cachedPeds[data.entity] = true
        offerDrug(data.entity)
    end
})

-- Every 30 minutes wipe cachedPeds so it won't effect performance...
SetInterval(function()
    cachedPeds = {}
end, 30000) --[[@as number?]]