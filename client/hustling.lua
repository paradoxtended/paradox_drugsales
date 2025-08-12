if Config.Hustling.disabled then return end

local Hustling = Config.Hustling

---@type { blip: integer, client: integer, point: CPoint, vehicle: integer, attempt: number, index: number }?
local currentHustle

---@param vehicle number
---@param door number
local function toggleDoor(vehicle, door)
    if GetVehicleDoorLockStatus(vehicle) ~= 2 then
        if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
            SetVehicleDoorShut(vehicle, door, false)
        else
            SetVehicleDoorOpen(vehicle, door, false, false)
        end
    end
end

local function onSelectDoor(data, door)
    local entity = data.entity

    if NetworkGetEntityOwner(entity) == cache.playerId then
        return toggleDoor(entity, door)
    end

    TriggerServerEvent('prp_drugsales:toggleEntityDoor', VehToNet(entity), door)
end

RegisterNetEvent('prp_drugsales:toggleEntityDoor', function(netId, door)
    local entity = NetToVeh(netId)
    toggleDoor(entity, door)
end)

local function endHustling(data, success)
    currentHustle.vehicle = currentHustle.vehicle and NetworkGetNetworkIdFromEntity(currentHustle.vehicle)

    if success then
        local success = lib.callback.await('prp_drugsales:finishHustle', false, currentHustle)

        if success then
            Config.Notify(locale('hustle.finished'), 'success')
            ---@todo synchronized scene after deal ends successfully
        end
    end

    currentHustle.client = currentHustle.client and NetworkGetNetworkIdFromEntity(currentHustle.client)
    TriggerServerEvent('prp_drugsales:endHustle', currentHustle)

    currentHustle = nil
    if data then onSelectDoor(data, 5) end
end

local function hustleWithClient(data)
    local items = lib.callback.await('prp_drugsales:getTrunkItems', false, NetworkGetNetworkIdFromEntity(data.entity))

    if #items == 0 then
        Config.Notify(locale('hustle.no_drugs_vehicle'), 'error')
        return
    end

    if not currentHustle.attempt then
        exports.ox_target:removeGlobalVehicle('prp_drugsales:vehiclePoint')
        currentHustle.attempt = 1

        -- Opens up the trunk
        onSelectDoor(data, 5)
        currentHustle.vehicle = data.entity

        local pos = GetWorldPositionOfEntityBone(currentHustle.vehicle, GetEntityBoneIndexByName(currentHustle.vehicle, 'boot'))
        TaskGoToCoordAnyMeans(currentHustle.client, pos.x, pos.y, pos.z, 1.0, 0, 0, 786603, 0xbf800000)

        while #(GetEntityCoords(currentHustle.client) - pos) > 1.75 do Wait(100) end

        SetEntityHeading(currentHustle.client, GetEntityHeading(currentHustle.vehicle))
        lib.playAnim(currentHustle.client, 'missheist_jewelleadinout', 'jh_int_outro_loop_a', 8.0, 8.0, 5000, 16)
        Config.ProgressBar(locale('hustle.browsing_drugs'), 5000, false, nil, nil, true)
        TaskTurnPedToFaceEntity(currentHustle.client, cache.ped, -1)
    else
        lib.playAnim(currentHustle.client, 'missheist_jewelleadinout', 'jh_int_outro_loop_a', 8.0, 8.0, 10000, 16)

        if not Config.ProgressBar(locale('hustle.renegotiating'), 10000, true, {
            dict = 'oddjobs@assassinate@vice@hooker',
            clip = 'argue_a',
            flag = 0
        }) then
            endHustling(data)
            return
        end

        currentHustle.attempt += 1
    end

    local result = waitForHustle(items, currentHustle.attempt < Hustling.attempts)
    
    if not result then return endHustling(data) end
    if result == 'negotiate' then return hustleWithClient(data) end
    if result == 'confirmed' then return endHustling(data, true) end
end

local function startHustling()
    FreezeEntityPosition(currentHustle.client, false)
    TaskTurnPedToFaceEntity(currentHustle.client, cache.ped, -1)
    TaskTurnPedToFaceEntity(cache.ped, currentHustle.client, -1)

    lib.playAnim(currentHustle.client, 'oddjobs@assassinate@vice@hooker', 'argue_a', 8.0, 8.0, 5000)

    if not Config.ProgressBar(locale('hustle.introducing_yourself'), 5000, true, {
        dict = 'oddjobs@assassinate@vice@hooker',
        clip = 'argue_a',
        flag = 0
    }) then
        FreezeEntityPosition(currentHustle.client, true)
        return
    end

    -- Make ped to follow player
    CreateThread(function()
        while not currentHustle.vehicle do
            TaskGoToEntity(currentHustle.client, cache.ped, -1, 2.0, 1.0, 0, 0)
            Wait(500)
        end
    end)

    currentHustle.point:remove()
    currentHustle.point = nil
    RemoveBlip(currentHustle.blip)
    currentHustle.blip = nil

    exports.ox_target:removeLocalEntity(currentHustle.client)
    exports.ox_target:addGlobalVehicle({
        label = locale('sell_drugs'),
        icon = 'fa-solid fa-boxes-packing',
        name = 'prp_drugsales:vehiclePoint',
        offset = vec3(0.5, 0, 0.5),
        distance = 2,
        onSelect = function(data)
            hustleWithClient(data)
        end
    })
end

local scenarios = {
    'WORLD_HUMAN_AA_COFFEE',
    'WORLD_HUMAN_AA_SMOKE',
    'WORLD_HUMAN_SMOKING'
}

---@param index integer
local function createClient(index)
    if currentHustle then return end

    local coords = Hustling.clients.locations[index]

    currentHustle = { index = index }

    local model = type(Hustling.clients.models) == 'string' and Hustling.clients.models
                or Utils.randomFromTable(Hustling.clients.models)

    currentHustle.blip = Utils.createRadiusBlip(coords, 70.0, 1)

    currentHustle.point = lib.points.new({
        coords = coords.xyz,
        distance = 100,
        onEnter = function()
            lib.requestModel(model)
            currentHustle.client = CreatePed(4, model, coords.x, coords.y, coords.z - 1.0, coords.w, true, true)
            FreezeEntityPosition(currentHustle.client, true)
            SetBlockingOfNonTemporaryEvents(currentHustle.client, true)
            TaskStartScenarioInPlace(currentHustle.client, Utils.randomFromTable(scenarios))

            exports.ox_target:addLocalEntity(currentHustle.client, {
                label = locale('hustle.introduce_yourself'),
                icon = 'fa-solid fa-handshake',
                distance = 2,
                onSelect = startHustling
            })
        end,
        onExit = function()
            if currentHustle.client and DoesEntityExist(currentHustle.client) then
                DeleteEntity(currentHustle.client)
                exports.ox_target:removeLocalEntity(currentHustle.client)
                currentHustle.client = nil
            end

            SetModelAsNoLongerNeeded(model)
        end
    })
end

RegisterNetEvent('prp_drugsales:createHustleClient', createClient)

lib.callback.register('prp_drugsales:startHustle', function()
    local success = Config.ProgressBar(locale('hustle.searching_clients'), 7500, true, {
        scenario = 'WORLD_HUMAN_STAND_MOBILE'
    })
    local fail = Hustling.clients.fail and Hustling.clients.fail > math.random(1, 100)

    if fail then
        Config.Notify(locale('hustle.failed_find_client'), 'error')
    end

    return success and not fail
end)

function isHustling()
    return currentHustle
end