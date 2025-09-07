local IsEntityDead = IsEntityDead
local GetEntityPopulationType = GetEntityPopulationType

-- Store NPCs so player won't be able to sell to one NPC forever
local cachedPeds = {}

exports.ox_target:addGlobalPed({
    label = locale('sell_drugs'),
    name = 'prp_drugsales:main',
    icon = 'fa-solid fa-joint',
    distance = 2,
    canInteract = function(entity)
        return not Utils.hasJob(Config.DisabledJobs)
        and Utils.hasDrug() 
        and not cachedPeds[entity]
        and not IsEntityDead(entity)
        and not prp.progressActive()
        and entity ~= getDealersPed()
        and GetEntityPopulationType(entity) ~= 7
    end,
    onSelect = function(data)
        cachedPeds[data.entity] = true
        offerDrug(data.entity)
    end
})

-- Every 30 minutes wipe cachedPeds so it won't effect performance...
SetInterval(function()
    cachedPeds = {}
end, 30 * 60000) --[[@as number?]]