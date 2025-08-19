---@type integer?, integer?
local ped, tablet

function removeTabletObject()
    ClearPedTasks(cache.ped)
    Wait(300)

    DeleteEntity(tablet)
    tablet = nil
end

local function createTabletObject()
    local model = `prop_cs_tablet`
    
    lib.requestModel(model)
    lib.requestAnimDict("amb@code_human_in_bus_passenger_idles@female@tablet@base")

    local coords = GetEntityCoords(cache.ped)
    tablet = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(cache.ped, 60309)

    SetCurrentPedWeapon(cache.ped, `weapon_unarmed`, true)
    AttachEntityToEntity(tablet, cache.ped, boneIndex, 0.03, 0.002, -0.0, 10.0, 160.0, 0.0, true, false, false, false, 2, true)
    SetModelAsNoLongerNeeded(`prop_cs_tablet`)

    TaskPlayAnim(cache.ped, "amb@code_human_in_bus_passenger_idles@female@tablet@base", "base", 3.0, 3.0, -1, 49, 0, 0, 0, 0)
end

local function showTablet()
    local users, admin = lib.callback.await('prp_drugsales:getLeaderboard', false)

    createTabletObject()
    Wait(100)

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'leaderboard',
        data = {
            users = users,
            admin = admin
        }
    })
end

for _, coords in ipairs(Config.Dealers.locations) do
    Utils.createPed(coords, Config.Dealers.models, {
        {
            label = locale('talk'),
            icon = 'fa-solid fa-comment',
            onSelect = showTablet
        }
    }, function(entity)
        ped = entity
    end)

    Utils.createBlip(coords, Config.Dealers.blip)
end

---@param data { identifier: string, type: 'nickname' | 'imageUrl', input: string }
RegisterNuiCallback('editProfile', function(data, cb)
    local success = lib.callback.await('prp_drugsales:editProfile', false, data)

    if success then
        Config.Notify(locale('edited_profile'), 'inform')
    end

    cb(success)
end)

function getDealersPed()
    return ped
end

AddEventHandler('baseevents:onPlayerKilled', function()
    removeTabletObject()
end)