if Config.Wholesale.disabled then return end

Framework.registerUsableItem(Config.Wholesale.requiredItem, function(source)
    local currentZone = lib.callback.await('prp_drugsales:getWholesaleZone', source)

    if not currentZone then
        TriggerClientEvent('prp-drugsales:notify', source, locale('not_in_zone'), 'error')
        return
    end

    local success = lib.callback.await('prp-drugsales:progress', source, locale('searching_client'), 8000, true, {
        scenario = 'WORLD_HUMAN_STAND_MOBILE'
    })

    if not success then return end

    
end)