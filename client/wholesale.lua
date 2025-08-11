if Config.Hustling.disabled then return end

local scenarios = {
    'WORLD_HUMAN_AA_COFFEE',
    'WORLD_HUMAN_AA_SMOKE',
    'WORLD_HUMAN_SMOKING'
}

---@type integer?
local currentLocation
---@type CPoint?, integer?
local point, ped
---@type integer?, boolean?
local blip, offered
---@type integer?
local currentVehicle
---@type number
local attempt = 0

local function endHustle()
    TriggerServerEvent('prp_drugsales:endHustle', currentLocation, NetworkGetNetworkIdFromEntity(ped))

    ClearPedTasks(cache.ped)
    ClearPedTasksImmediately(ped)
    TaskSmartFleePed(ped, cache.ped, 100.0, -1, false, false)
    SetVehicleDoorShut(currentVehicle, 5, false)

    -- Reseting values
    blip = nil
    point = nil
    currentVehicle = nil
    offered = nil
    currentLocation = nil
    ped = nil
    attempt = 0
end

local function pedHelper()
    offered = offered == nil

    if offered then
        SetVehicleDoorOpen(currentVehicle, 5, false, false)

        local pos = GetWorldPositionOfEntityBone(currentVehicle, GetEntityBoneIndexByName(currentVehicle, 'boot'))
        TaskGoToCoordAnyMeans(ped, pos.x, pos.y, pos.z, 1.0, 0, 0, 786603, 0xbf800000)

        while #(GetEntityCoords(ped) - pos) > 1.75 do Wait(200) end

        local heading = GetEntityHeading(currentVehicle)
        TaskAchieveHeading(ped, heading, 10000)

        while Absf(GetEntityHeading(ped) - heading) > 10.0 do Wait(200) end

        lib.playAnim(ped, 'missheist_jewelleadinout', 'jh_int_outro_loop_a', 8.0, 8.0, 5000, 16)

        Config.ProgressBar(locale('hustle.customer_browsing_drugs'), 5000, false, nil, nil, true)
        offered = false

        TaskTurnPedToFaceEntity(ped, cache.ped, -1)
        TaskTurnPedToFaceEntity(cache.ped, ped, -1)
    else
        lib.playAnim(ped, 'missheist_jewelleadinout', 'jh_int_outro_loop_a', 8.0, 8.0, 5000, 16)

        if not Config.ProgressBar(locale('hustle.renegotiating_deal'), 5000, true, {
            dict = 'oddjobs@assassinate@vice@hooker',
            clip = 'argue_a',
            flag = 0
        }) then endHustle() end
    end
end

local function showDrugs()
    attempt += 1

    if attempt > (Config.Hustling.hustling.attempts or 3) then
        Config.Notify(locale('hustle.client_refused'), 'error')
        return endHustle()
    end

    exports.ox_target:removeLocalEntity(currentVehicle)
    prp.hideObjective()

    pedHelper()

    local items = lib.callback.await('prp_drugsales:getHustleItems', false)

    if #items == 0 then 
        return Config.Notify(locale('hustle.nothing_to_offer'))
    end

    local result = waitForHustle(items)

    if result == 'negotiate' then return showDrugs() end
    if not result then return endHustle() end
end

local function hustle()
    if not currentVehicle
    or not IsThisModelACar(GetEntityModel(currentVehicle)) then
        return Config.Notify(locale('hustle.no_vehicle'), 'error')
    end

    FreezeEntityPosition(ped, false)

    TaskTurnPedToFaceEntity(ped, cache.ped, -1)
    TaskTurnPedToFaceEntity(cache.ped, ped, -1)

    while not IsPedFacingPed(cache.ped, ped, 5.0)
    or not IsPedFacingPed(ped, cache.ped, 5.0) do Wait(100) end

    lib.playAnim(ped, 'oddjobs@assassinate@vice@hooker', 'argue_a', 8.0, 8.0, 5000)

    if not Config.ProgressBar(locale('hustle.introducing_yourself'), 5000, true, {
        dict = 'oddjobs@assassinate@vice@hooker',
        clip = 'argue_a',
        flag = 0
    }) then
        FreezeEntityPosition(ped, true)
        return
    end

    prp.showObjective(locale('hustle.hustling'), locale('hustle.offer_drugs'))
    RemoveBlip(blip)
    exports.ox_target:removeLocalEntity(ped)
    point:remove()

    -- Ped follows player
    CreateThread(function()
        while not offered do
            TaskGoToEntity(ped, cache.ped, -1, 2.0, 1.0, 0, 0)
            Wait(500)
        end
    end)

    -- Create point for vehicle's trunk
    exports.ox_target:addLocalEntity(currentVehicle, {
        icon = 'fa-solid fa-boxes-packing',
        label = locale('sell_drugs'),
        offset = vec3(0.5, 0, 0.5),
        distance = 2,
        onSelect = function()
            showDrugs()
        end
    })
end

---@param coords vector4
local function createClient(coords)
    prp.showObjective(locale('hustle.hustling'), locale('hustle.go_to_client'))
    blip = Utils.createRadiusBlip(coords, 50.0, 1)

    local model = type(Config.Hustling.clients.models) == 'string' and Config.Hustling.clients.models
                or Utils.randomFromTable(Config.Hustling.clients.models)
    
    point = lib.points.new({
        coords = coords.xyz,
        distance = 50.0,
        onEnter = function()
            lib.requestModel(model)
            ped = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, true, false)
            SetEntityInvincible(ped, true)
            FreezeEntityPosition(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            TaskStartScenarioInPlace(ped, Utils.randomFromTable(scenarios))
            currentVehicle = cache.vehicle

            -- Remove main interaction (offer drugs)
            exports.ox_target:removeGlobalPed('prp_drugsales:main_interaction')

            exports.ox_target:addLocalEntity(ped, {
                label = locale('hustle.introduce_yourself'),
                icon = 'fa-solid fa-handshake',
                onSelect = function()
                    hustle()
                end
            })
        end,
        onExit = function()
            DeleteEntity(ped)
            SetModelAsNoLongerNeeded(model)
            exports.ox_target:removeLocalEntity(ped)
            ped = nil
            currentVehicle = nil
        end
    })
end

---@type integer?
local pending

local function startHustle()
    -- Delay system
    if pending then
        local delay = (Config.Hustling.delay or 10) * 60000
        local timeSpent = GetGameTimer() - pending
        local timeLeft = delay - timeSpent
        
        if timeLeft > 0 then
            local minutes = math.floor(timeLeft / 60000)
            local seconds = math.floor(timeLeft / 1000) % 60

            return Config.Notify(locale('hustle.delay_message', ("%d minutes %02d seconds"):format(minutes, seconds)), 'error')
        end

        pending = nil
    end

    if not Config.ProgressBar(locale('hustle.searching_client'), 7500, true, {
        scenario = 'WORLD_HUMAN_STAND_MOBILE'
    }) then return end

    -- Random event ... player failed to find a client
    local fail = Config.Hustling.clients.fail

    if fail and fail >= math.random(100) then
        return Config.Notify(locale('hustle.failed_to_find_client'), 'error')
    end

    pending = GetGameTimer()
    
    local coords, locationIndex = lib.callback.await('prp_drugsales:getHustleClient', false)

    if not coords or not locationIndex then
        -- After 2000 attempts still no coords??
        return Config.Notify(locale('hustle.no_client_available'), 'error')
    end

    currentLocation = locationIndex

    createClient(coords)
end

RegisterNetEvent('prp_drugsales:startHustle', startHustle)