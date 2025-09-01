if Config.Quests.disabled then return end

---@class Quest
---@field claimed boolean
---@field item string
---@field amount { done: number, required: number }
---@field reward number

---@type table<string, Quest[]>, table<string, Quest[]>
local quests, weekly = {}, {}
---@type table<string, { daily: number, weekly: number }>
local refreshed = {}

-- Cron expression that runs every sunday at 23:59, make sure your server is on!
lib.cron.new('59 23 * * SUN', function()
    table.wipe(weekly)
end)

---@param questType 'daily' | 'weekly'?
---@return Quest
local function generateQuest(questType)
    local data, item = Utils.randomFromTable(Config.Drugs)

    local amount = (type(data.amount) == 'number' and data.amount or math.random(data.amount.min, data.amount.max)) * Config.Quests[questType or 'daily'].multiplier.amount
    local price = (math.random(data.price.min, data.price.max) * amount) * Config.Quests[questType or 'daily'].multiplier.price
    
    return {
        item = item,
        amount = { done = 0, required = amount },
        reward = math.floor(price)
    }
end

---@param identifier string
function createQuests(identifier)
    if quests[identifier] and #quests[identifier] >= Config.Quests.amount then return end

    local Quests = {}

    for i = 1, Config.Quests.amount do
        Quests[i] = generateQuest()
    end

    quests[identifier] = Quests
end

---@param identifier string
local function getWeeklyQuests(identifier)
    if not weekly[identifier] or #weekly[identifier] < 1 then
        weekly[identifier] = {}

        local quests = weekly[identifier]

        for i = 1, Config.Quests.amount do
            quests[i] = generateQuest('weekly')
        end

        local query = 'UPDATE prp_drugsales SET quests = ? WHERE identifier = ?'
        MySQL.insert.await(query, { json.encode(quests), identifier })
    end

    return weekly[identifier]
end

---@param source number
---@param targetIdentifier string
---@param type 'daily' | 'weekly'
lib.callback.register('prp_drugsales:getPlayerQuests', function(source, targetIdentifier, type)
    local player = Framework.getPlayerFromId(source)

    if not player 
    or type == 'daily' and not quests[targetIdentifier] then 
        return
    end

    local identifier = player:getIdentifier()

    if not player:hasOneOfGroups(Config.AdminGroups) and identifier ~= targetIdentifier then return end

    local weeklyQuests = getWeeklyQuests(targetIdentifier)

    return type == 'daily' and quests[targetIdentifier]
        or weeklyQuests
end)

---@param source number
---@param targetIdentifier string
---@param id number
---@param type 'daily' | 'weekly'
lib.callback.register('prp_drugsales:refreshQuest', function(source, targetIdentifier, id, type)
    local player = Framework.getPlayerFromId(source)

    if not refreshed[targetIdentifier] then
        refreshed[targetIdentifier] = {}
    end

    if not player 
    or not quests[targetIdentifier] 
    or (refreshed[targetIdentifier][type] or 0) >= Config.Quests[type].refreshCount then 
        return
    end

    local identifier = player:getIdentifier()

    if not player:hasOneOfGroups(Config.AdminGroups) and identifier ~= targetIdentifier then return end

    -- Convert id from JS to LUA by adding 1
    local id = id + 1

    refreshed[targetIdentifier][type] = (refreshed[targetIdentifier][type] or 0) + 1

    if type == 'daily' then
        quests[targetIdentifier][id] = generateQuest(type)
    else
        weekly[targetIdentifier][id] = generateQuest(type)
    end

    return type == 'daily' and quests[targetIdentifier]
        or weekly[targetIdentifier]
end)

---@param source number
---@param targetIdentifier string
---@param id number
---@param type 'daily' | 'weekly'
lib.callback.register('prp_drugsales:claimQuest', function(source, targetIdentifier, id, type)
    local player = Framework.getPlayerFromId(source)
    local target = Framework.getPlayerFromIdentifier(targetIdentifier)

    -- Convert id from JS to LUA by adding 1
    local id = id + 1

    local quest = type == 'daily' and quests[targetIdentifier][id] or weekly[targetIdentifier][id]

    if not player
    or not quest
    or quest.amount.done < quest.amount.required then
        return false, locale('quest_not_finished')
    end

    if not target or quest.claimed then return end

    local identifier = player:getIdentifier()

    if not player:hasOneOfGroups(Config.AdminGroups) and identifier ~= targetIdentifier then 
        return false, locale('quest_not_owner')
    end

    quest.claimed = true

    local account = Config.Quests[type].account or Config.DefaultAccount
    target:addAccountMoney(account, quest.reward)

    return type == 'daily' and quests[targetIdentifier] or weekly[targetIdentifier], locale('quest_claimed')
end)

---@param player Player
---@param drugName string
---@param amount number
function updateQuests(player, drugName, amount)
    local identifier = player:getIdentifier()
    local Daily, Weekly = quests[identifier], weekly[identifier]

    -- Check if there is a quest with this drug
    for _, quest in ipairs(Daily) do
        if quest.item == drugName then
            quest.amount.done += amount
        end
    end

    for _, quest in ipairs(Weekly) do
        if quest.item == drugName then
            quest.amount.done += amount
        end
    end
end

---@param identifier string
function getPlayerWeeklyQuests(identifier)
    return weekly[identifier] or {}
end

function initWeeklyQuests()
    return weekly
end