---@type integer?
local ped

local function showTablet()
    local users, admin = lib.callback.await('prp_drugsales:getLeaderboard', false)

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