if Config.Hustling.disabled then return end

local Hustling = Config.Hustling

---@type { blip: integer, client: integer, point: CPoint, vehicle: integer }?
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

local function hustleWithClient(data)
    currentHustle.vehicle = data.entity

    local items = lib.callback.await('prp_drugsales:getTrunkItems', false, NetworkGetNetworkIdFromEntity(currentHustle.vehicle))

    print(#items)
end

local function startHustling()
    FreezeEntityPosition(currentHustle.client, false)
    TaskTurnPedToFaceEntity(currentHustle.client, cache.ped, -1)
    TaskTurnPedToFaceEntity(cache.ped, currentHustle.client, -1)

    while not IsPedFacingPed(currentHustle.client, cache.ped, 10.0)
    or not IsPedFacingPed(cache.ped, currentHustle.client, 10.0) do Wait(100) end

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

    exports.ox_target:addGlobalVehicle({
        label = locale('sell_drugs'),
        icon = 'fa-solid fa-boxes-packing',
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

---@param coords vector4
local function createClient(coords)
    if currentHustle then return end

    currentHustle = {}

    local model = type(Hustling.clients.models) == 'string' and Hustling.clients.models
                or Utils.randomFromTable(Hustling.clients.models)

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
            end

            SetModelAsNoLongerNeeded(model)
        end
    })
end

RegisterNetEvent('prp_drugsales:createHustleClient', createClient)

lib.callback.register('prp_drugsales:startHustle', function()
    local success = Config.ProgressBar(locale('searching_clients'), 7500, true, {
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