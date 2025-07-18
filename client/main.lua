local busy
---@type { normal: integer, radius: integer }[], CZone[]
local blips, zones = {}, {}
---@type { index: string, locationIndex: integer }?, integer?
local currentZone, currentNPC

lib.callback.register('prp-drugsales:currentZone', function()
    return currentZone
end)

local function removeZones()
    for _, blip in ipairs(blips) do
        RemoveBlip(blip.normal)
        RemoveBlip(blip.radius)
    end

    for _, zone in ipairs(zones) do
        zone:remove()
    end

    table.wipe(blips)
    table.wipe(zones)
end

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

    for drugName, drug in pairs(Config.Drugs) do
        if not zone and (not drug.zones or #drug.zones == 0) and Framework.hasItem(drugName) then
            table.insert(drugs, drugName)
        elseif zone and lib.table.contains(drug.zones, zone) and Framework.hasItem(drugName) then
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
        local sold = lib.callback.await('prp-drugsales:sell', false, drugName, price, amount)

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

    AttachEntityToEntity(object, currentNPC, boneIndex, 
    0.06, 0.0, -0.02, 
    0.0, 0.0, 0.0, 
    true, true, false, true, 1, true)

    lib.playAnim(currentNPC, 'mp_common', 'givetake1_b', 8.0, 8.0, 3000)
    
    SetTimeout(3000, function()
        DeleteEntity(object)
    end)

    SetModelAsNoLongerNeeded(model)
end

---@param drugName string
lib.callback.register('prp-drugsales:animation', function(drugName)
    local prop = Config.Drugs[drugName]

    pedBehaviour(true)
    createAnimation()

    local success = Config.ProgressBar(locale('handing_over_drugs'), 3000, true, {
        clip = 'givetake1_a', dict = 'mp_common'
    }, {
        model = `prop_meth_bag_01`, bone = 28422,
        pos = { x = -0.015, y = 0.015, z = 0.025 },
        rot = { x = -90.0, y = 0.0, z = 0.0 }
    })

    return success
end)