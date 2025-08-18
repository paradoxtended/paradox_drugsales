---@class User
---@field identifier string
---@field name string
---@field nickname string
---@field imageUrl string
---@field stats { earned: number, lastActive: string | osdate, reputation: number }
---@field drugs table<string, { label: string, amount: number }>
---@field myself boolean

---@type table<string, User>
local users = {}

MySQL.ready(function()
    local data = MySQL.query.await('SELECT * FROM prp_drugsales')

    for _, entry in ipairs(data) do
        local data = json.decode(entry.data)
        
        users[entry.identifier] = {
            identifier = entry.identifier,
            name = data.name,
            nickname = data.nickname,
            imageUrl = data.imageUrl,
            stats = data.stats,
            drugs = data.drugs
        }
    end
end)

---@param source number
---@return User[]?, boolean?
lib.callback.register('prp_drugsales:getLeaderboard', function(source)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    ---@type User[]
    local Users = {}

    for identifier, user in pairs(users) do
        user.myself = identifier == player:getIdentifier()

        table.insert(Users, user)
    end

    return Users, player:hasOneOfGroups(Config.AdminGroups)
end)

---@param source number
---@param data { identifier: string, type: 'nickname' | 'imageUrl', input: string }
lib.callback.register('prp_drugsales:editProfile', function(source, data)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    local identifier, type, input in data

    if identifier ~= player:getIdentifier() and not player:hasOneOfGroups(Config.AdminGroups) then return end

    users[identifier][type] = input

    return true
end)

---@param player Player
---@param drugName string
---@param amount number
function addPlayerDrug(player, drugName, amount)
    users[player:getIdentifier()]?.drugs[drugName]?.amount += amount
end

---@param player Player
---@param amount number
function addPlayerEarnings(player, amount)
    users[player:getIdentifier()]?.stats.earned += amount
end

---@param player Player
function getDealerUser(player)
    return users[player:getIdentifier()]
end