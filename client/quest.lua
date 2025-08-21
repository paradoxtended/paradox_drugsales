---@param rawQuests Quest[]
local function getDescribedQuests(rawQuests)
    local quests = {}

    for _, quest in ipairs(rawQuests) do
        table.insert(quests, {
            title = locale('quest_title', quest.amount.done, quest.amount.required, Utils.getItemLabel(quest.item), 
                    quest.reward),
            description = locale('quest_description'),
            progress = (quest.amount.done / quest.amount.required) * 100,
            claimed = quest.claimed
        })
    end

    return quests
end

---@param identifier string
RegisterNUICallback('getQuests', function(identifier, cb)
    ---@type Quest[]
    local rawQuests = lib.callback.await('prp_drugsales:getPlayerQuests', false, identifier)

    if not rawQuests then
        cb(0)
        return
    end

    local quests = getDescribedQuests(rawQuests)

    cb(quests)
end)

---@param data { identifier: string, id: number }
RegisterNUICallback('refreshQuest', function(data, cb)
    local identifier, id in data

    local newQuests = lib.callback.await('prp_drugsales:refreshQuest', false, identifier, id)

    if not newQuests then
        Config.Notify(locale('quest_cant_refresh'), 'error')
        cb(0)
        return
    end

    local quests = getDescribedQuests(newQuests)

    cb(quests)
end)

---@param data { identifier: string, id: number }
RegisterNUICallback('claimQuest', function(data, cb)
    local identifier, id in data

    local newQuests, msg = lib.callback.await('prp_drugsales:claimQuest', false, identifier, id)

    if newQuests then
        Config.Notify(msg, 'success')
        local quests = getDescribedQuests(newQuests)

        cb(quests)

        return
    elseif msg then
        Config.Notify(msg, 'error')
    end

    cb(0)
end)