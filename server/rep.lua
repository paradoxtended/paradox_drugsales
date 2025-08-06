local createQuery = [[
    CREATE TABLE IF NOT EXISTS `prp_drugsales` (
        `identifier` varchar(50) NOT NULL,
        `reputation` float NOT NULL,
        PRIMARY KEY (`identifier`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
]]

---@type table<string, integer>
local reps = {}

MySQL.ready(function()
    MySQL.query.await(createQuery)
    
    local data = MySQL.query.await('SELECT * FROM prp_drugsales')

    for _, entry in ipairs(data) do
        reps[entry.identifier] = entry.reputation
    end
end)

local function save()
    local query = 'UPDATE prp_drugsales SET reputation = ? WHERE identifier = ?'
    local parameters = {}
    local size = 0

    for identifier, rep in pairs(reps) do
        size += 1
        parameters[size] = {
            rep,
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


local function createPlayer(identifier)
    reps[identifier] = 0.0
    MySQL.insert.await('INSERT INTO prp_drugsales (identifier, reputation) VALUES (?, ?)', { identifier, reps[identifier] })
end

lib.callback.register('prp_drugsales:getReputation', function(source)
    local player = Framework.getPlayerFromId(source)

    if not player then return end

    local identifier = player:getIdentifier()

    if not reps[identifier] then
        createPlayer(identifier)
    end

    return reps[identifier]
end)

---Add or remove player's reputation
---@param player Player
---@param amount number
function addPlayerRep(player, amount)
    local identifier = player:getIdentifier()

    reps[identifier] += amount

    TriggerClientEvent('prp_drugsales:updateReputation', player.source, reps[identifier])
end

---@param player Player
---@return number
function getPlayerRep(player)
    return reps[player:getIdentifier()]
end