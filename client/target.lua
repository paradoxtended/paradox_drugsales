exports.ox_target:addGlobalPed({
    label = locale('sell_drugs'),
    icon = 'fa-solid fa-joint',
    canInteract = function(_, distance)
        return distance <= 2.0 and not Utils.hasJob(Config.DisabledJobs) and Utils.hasDrug()
    end,
    onSelect = function(data)
        offerDrug(data.entity)
    end
})