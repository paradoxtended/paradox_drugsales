---@class Quest
---@field claimed boolean
---@field item string
---@field amount { done: number, required: number }

---@type table<string, Quest[]>
local quests = {}

local function generateQuest()
    local quest = Utils.randomFromTable(Config.Drugs)
end

---@param identifier string
function createQuests(identifier)
    if quests[identifier] and #quests[identifier] >= Config.Quests.amount then return end
    local Quests = {}

    for i = 1, #Config.Quests.amount do
        Quests[i] = generateQuest()
    end
end