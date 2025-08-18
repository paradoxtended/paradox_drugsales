---@class User
---@field identifier string
---@field name string
---@field nickname string
---@field imageUrl string
---@field stats { earned: number, lastActive: string | osdate, reputation: number }
---@field drugs table<string, { label: string, amount: number }>
---@field online boolean
---@field myself boolean

---@type table<string, User>
local users = {}

MySQL.ready(function()
    local status, data = pcall(function()
        return MySQL.query.await('SELECT * FROM prp_drugsales')
    end)

    if status then
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
    end
end)

local function save()
    local query = 'UPDATE prp_drugsales SET data = ? WHERE identifier = ?'
    local parameters = {}
    local size = 0

    for identifier, user in pairs(users) do
        size += 1
        parameters[size] = {
            json.encode(user),
            identifier
        }
    end

    if size > 0 then
        MySQL.prepare.await(query, parameters)
    end
end

lib.cron.new('*/30 * * * *', save)
AddEventHandler('txAdmin:events:serverShuttingDown', save)

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining ~= 60 then return end

	save()
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == cache.resource then
		save()
	end
end)

---@param player Playuer
---@return User[]
local function getConvertedUsers(player)
    local Users = {}
    ---@type table<string, User>
    local clone = lib.table.deepclone(users)

    for identifier, user in pairs(clone) do
        local target = Framework.getPlayerFromIdentifier(identifier)

        -- Create temporary values for UI
        user.myself = identifier == player:getIdentifier()
        user.online = target and true
        user.identifier = identifier
        user.stats.reputation = getPlayerRep(identifier)

        table.insert(Users, user)
    end

    return Users
end

---@param source number
---@return User[]?, boolean?
lib.callback.register('prp_drugsales:getLeaderboard', function(source)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    return getConvertedUsers(player), player:hasOneOfGroups(Config.AdminGroups)
end)

---@param source number
---@param data { identifier: string, type: 'nickname' | 'imageUrl', input: string }
lib.callback.register('prp_drugsales:editProfile', function(source, data)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    local identifier, type, input in data

    if identifier ~= player:getIdentifier() and not player:hasOneOfGroups(Config.AdminGroups) then return end

    users[identifier][type] = input

    return getConvertedUsers(player)
end)

---@param player Player
---@param drugName string
---@param amount number
function addPlayerDrug(player, drugName, amount)
    local user = users[player:getIdentifier()]

    if not user then return end

    local data = user.drugs[drugName]

    if not data then
        user.drugs[drugName] = { amount = amount, label = Utils.getItemLabel(drugName) }
    else
        user.drugs[drugName].amount += amount
    end
end

---@param player Player
---@param amount number
function addPlayerEarnings(player, amount)
    users[player:getIdentifier()]?.stats.earned += amount
end

---@param identifier string
---@param data User
function addPlayerLeaderboard(identifier, data)
    users[identifier] = {
        name = data.name,
        nickname = data.nickname,
        imageUrl = data.imageUrl,
        stats = data.stats,
        drugs = data.drugs
    }
end

---@param player Player
function getDealerUser(player)
    return users[player:getIdentifier()]
end