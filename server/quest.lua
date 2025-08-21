---@class Quest
---@field claimed boolean
---@field item string
---@field amount { done: number, required: number }
---@field reward number

---@type table<string, Quest[]>
local quests = {}
---@type table<string, number>
local refreshed = {}

---@return Quest
local function generateQuest()
    local data, item = Utils.randomFromTable(Config.Drugs)

    local amount = (type(data.amount) == 'number' and data.amount or math.random(data.amount.min, data.amount.max)) * Config.Quests.daily.multiplier.amount
    local price = (math.random(data.price.min, data.price.max) * amount) * Config.Quests.daily.multiplier.price
    
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

---@param source number
---@param targetIdentifier string
lib.callback.register('prp_drugsales:getPlayerQuests', function(source, targetIdentifier)
    local player = Framework.getPlayerFromId(source)

    if not player or not quests[targetIdentifier] then return end

    local identifier = player:getIdentifier()

    if not player:hasOneOfGroups(Config.AdminGroups) and identifier ~= targetIdentifier then return end

    return quests[targetIdentifier]
end)

---@param source number
---@param targetIdentifier string
---@param id number
lib.callback.register('prp_drugsales:refreshQuest', function(source, targetIdentifier, id)
    local player = Framework.getPlayerFromId(source)

    if not player 
    or not quests[targetIdentifier] 
    or refreshed[targetIdentifier] and refreshed[targetIdentifier] >= Config.Quests.daily.refreshCount then 
        return
    end

    local identifier = player:getIdentifier()

    if not player:hasOneOfGroups(Config.AdminGroups) and identifier ~= targetIdentifier then return end

    -- Convert id from JS to LUA by adding 1
    local id = id + 1

    refreshed[targetIdentifier] = (refreshed[targetIdentifier] or 0) + 1
    quests[targetIdentifier][id] = generateQuest()

    return quests[targetIdentifier]
end)

---@param source number
---@param targetIdentifier string
---@param id number
lib.callback.register('prp_drugsales:claimQuest', function(source, targetIdentifier, id)
    local player = Framework.getPlayerFromId(source)
    local target = Framework.getPlayerFromIdentifier(targetIdentifier)

    -- Convert id from JS to LUA by adding 1
    local id = id + 1

    local quest = quests[targetIdentifier][id]

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

    local account = Config.Quests.daily.account or Config.DefaultAccount
    target:addAccountMoney(account, quest.reward)

    return quests[targetIdentifier], locale('quest_claimed')
end)

---@param player Player
---@param drugName string
---@param amount number
function updateQuests(player, drugName, amount)
    local identifier = player:getIdentifier()
    local Quests = quests[identifier]

    -- Check if there is a quest with this drug
    for _, quest in ipairs(Quests) do
        if quest.item == drugName then
            quest.amount.done += amount
        end
    end
end