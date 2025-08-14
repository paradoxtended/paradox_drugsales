local busy
---@type { normal: integer, radius: integer }[], CZone[]
local blips, zones = {}, {}
---@type { index: string, locationIndex: integer }?, integer?
local currentZone, currentNPC

lib.callback.register('prp-drugsales:currentZone', function()
    return currentZone
end)

local function createZones()
    for index, data in pairs(Config.SellingZones) do
        local radius = data.radius or Config.DefaultRadius

        for locationIndex, coords in ipairs(data.locations) do
            if data.blip then
                local blip = Utils.createBlip(coords, data.blip)
                local radiusBlip = Utils.createRadiusBlip(coords, radius, data.blip.color)

                table.insert(blips, { normal = blip, radius = radiusBlip })
            end

            local zone = lib.zones.sphere({
                coords = coords,
                radius = radius,
                onEnter = function()
                    if currentZone?.index == index and currentZone?.locationIndex == locationIndex then return end

                    currentZone = { index = index, locationIndex = locationIndex }

                    if data.message then
                        Config.Notify(data.message.enter, 'inform')
                    end
                end,
                onExit = function()
                    if currentZone?.index ~= index and currentZone?.locationIndex ~= locationIndex then return end

                    currentZone = nil

                    if data.message then
                        Config.Notify(data.message.exit, 'inform')
                    end
                end
            })

            table.insert(zones, zone)
        end
    end
end

createZones()

local interval

---@param reset boolean?
local function pedBehaviour(reset)
    if reset then
        ClearPedTasks(cache.ped)
        ClearPedTasks(currentNPC)

        if interval then
            ClearInterval(interval)
            interval = nil
        end

        return
    end

    ClearPedTasks(currentNPC)
    TaskTurnPedToFaceEntity(currentNPC, cache.ped, -1)
    TaskTurnPedToFaceEntity(cache.ped, currentNPC, -1)
    SetBlockingOfNonTemporaryEvents(currentNPC, true)

    while not IsPedFacingPed(currentNPC, cache.ped, 15.0)
    or not IsPedFacingPed(cache.ped, currentNPC, 15.0) do Wait(100) end

    interval = SetInterval(function()
        if not IsEntityPlayingAnim(currentNPC, 'missheist_jewelleadinout', 'jh_int_outro_loop_a', 3) and interval then
            lib.playAnim(currentNPC, 'missheist_jewelleadinout', 'jh_int_outro_loop_a', 8.0, 8.0, -1, 16)
        end
    end, 10) --[[@as number?]]
end

---@param zone string?
---@return string[]
local function getZoneDrugs(zone)
    local drugs = {}
    local allowAll = Config.SellingZones[zone]?.includeAll

    for drugName, drug in pairs(Config.Drugs) do
        if not zone and (not drug.zones or #drug.zones == 0) and Framework.hasItem(drugName) then
            table.insert(drugs, drugName)
        elseif zone and (drug.zones and lib.table.contains(drug.zones, zone) or allowAll) and Framework.hasItem(drugName) then
            table.insert(drugs, drugName)
        end
    end

    return drugs
end

---@param drugName string
---@param price number
---@param amount number
local function sellDrug(drugName, price, amount)
    local drug = Config.Drugs[drugName]

    if not drug then return end

    local progress = Config.ProgressBar(locale('giving_offer'), 3500, true, { clip = 'youthinkyourhappy_7', dict = 'special_ped@jerome@monologue_6@monologue_6h' })

    if progress then
        local sold = lib.callback.await('prp-drugsales:sell', false, drugName, price, amount, NetworkGetNetworkIdFromEntity(currentNPC))

        if sold then
            Config.Notify(locale('deal_success'), 'success')
        end
    end

    pedBehaviour(true)
end

---@param npc integer
function offerDrug(npc)
    local drugs = getZoneDrugs(currentZone?.index)

    if not drugs or #drugs < 1 then
        return Config.Notify(locale('nothing_to_offer'), 'error')
    end

    if busy then return end

    busy = true
    currentNPC = npc
    pedBehaviour()

    local progress = Config.ProgressBar(locale('offering_drugs'), 3500, true, { clip = 'bill_ig_1_b_01_imofferingironclad_6', dict = 'special_ped@bill@monologue_4@monologue_4g' })

    if progress then
        local drug = Utils.randomFromTable(drugs)
        local price, amount = waitForPrice(drug)

        if price then
            sellDrug(drug, price, amount)
        else
            pedBehaviour(true)
        end
    else
        pedBehaviour(true)
        currentNPC = nil
    end

    busy = nil
end

local function createAnimation()
    local model = `prop_anim_cash_pile_01`

    lib.requestModel(model)

    local coords = GetEntityCoords(cache.ped)
    local object = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(currentNPC, 28422)

    AttachEntityToEntity(object, currentNPC, boneIndex, 0.07, 0.025, -0.02, 45.0, 45.0, 0.0, true, true, false, true, false, true)

    lib.playAnim(currentNPC, 'mp_common', 'givetake1_b', 8.0, 8.0, 3000)
    
    CreateThread(function()
        local boneIndex = GetPedBoneIndex(cache.ped, 28422)

        Wait(1500)
        DetachEntity(object, true, false)
        AttachEntityToEntity(object, cache.ped, boneIndex, 0.0, 0.0, 0.02, 45.0, 45.0, 0.0, true, true, false, true, false, true)

        Wait(1500)
        DeleteEntity(object)
    end)

    SetModelAsNoLongerNeeded(model)
end

---@param drugName string
lib.callback.register('prp-drugsales:animation', function(drugName)
    local model = Config.Drugs[drugName].prop or `prop_meth_bag_01`

    lib.requestModel(model)

    local coords = GetEntityCoords(cache.ped)
    local object = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(cache.ped, 28422)

    pedBehaviour(true)
    createAnimation()

    local pos = vec3(-0.015, 0.015, 0.025)
    local rot = vec3(-90.0, 0.0, 0.0)

    AttachEntityToEntity(object, cache.ped, boneIndex, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, false, true, false, true)

    CreateThread(function()
        local boneIndex = GetPedBoneIndex(currentNPC, 28422)

        Wait(1500)
        DetachEntity(object, true, false)
        AttachEntityToEntity(object, currentNPC, boneIndex, 0.07, 0.02, -0.02, -50.0, 0.0, 0.0, true, true, false, true, false, true)

        Wait(1500)
        DeleteEntity(object)
    end)

    SetModelAsNoLongerNeeded(model)

    local success = Config.ProgressBar(locale('handing_over_drugs'), 3000, true, { clip = 'givetake1_a', dict = 'mp_common' })

    return success
end)

RegisterNetEvent('prp_drugsales:registerRobbery', function(netId)
    exports.ox_target:addEntity(netId, {
        label = locale('take_drugs'),
        icon = 'fa-solid fa-hand',
        distance = 2,
        canInteract = function(entity)
            return IsPedDeadOrDying(entity, false) and not prp.progressActive()
        end,
        onSelect = function()
            if not Config.ProgressBar(locale('searching_drugs'), 5000, true, {
                dict = 'missbigscore2aig_7@driver',
                clip = 'boot_r_loop',
                flag = 1
            }) then return end

            local success = lib.callback.await('prp_drugsales:robbery', false, netId)

            if success then
                Config.Notify(locale('drugs_took'), 'inform')
            end
        end
    })
end)

RegisterNetEvent('prp_drugsales:unregisterRobbery', function(netId)
    exports.ox_target:removeEntity(netId)
end)

RegisterNetEvent('prp_drugsales:attack', Utils.attackPlayer)
RegisterNetEvent('prp_drugsales:rob', Utils.robPlayer)