Config = {}

--- Default radius ... if radius is not defined in selling zone
Config.DefaultRadius = 100.0
--- Jobs that cannot offer drugs to NPCs
Config.DisabledJobs = { 'police', 'sheriff', 'ambulance' }
--- Default accept chance, used when player is not in zone or acceptChance is not specified in zone
Config.DefaultAcceptChance = 50.0

---@class BlipData
---@field name string;
---@field sprite integer;
---@field color integer;
---@field scale number;

---@class Drug
---@field price { min: number, max: number };
---@field amount { min: number, max: number } | number;
---@field zones? string[]; If defined then you need to be in one of the specified zone to be able to sell the drug. Zone has to be created in Config.SellingZones

---@type table<string, Drug>
Config.Drugs = {
    ['meth_bag'] = {
        price = {
            min = 125,
            max = 180
        },
        amount = {
            min = 1,
            max = 5
        },
        zones = { 'Forum Drive' }
    }
}

---@class SellingZone
---@field blip? BlipData;
---@field locations vector3[];
---@field radius? number;
---@field message? { enter: string, exit: string };
---@field acceptChance? number;

---@type table<string, SellingZone>
Config.SellingZones = {
    ['Forum Drive'] = {
        blip = {
            name = 'Forum Drive',
            sprite = 51,
            scale = 0.8,
            color = 52
        },
        locations = {
            vector3(-35.9035, -1456.1980, 31.2915)
        }
    }
}

--- Editable codes
if not IsDuplicityVersion() then
    ---If you want to change your notification script, feel free to do so, but function params must be the same!!
    ---@param content string
    ---@param type 'inform' | 'error' | 'success'
    Config.Notify = function(content, type)
        prp.notify({
            description = content,
            type = type
        })
    end

    ---@param text string
    ---@param duration number
    ---@param canCancel? boolean
    ---@param anim? any
    ---@param prop? any
    Config.ProgressBar = function(text, duration, canCancel, anim, prop)
        return prp.progressBar({
            duration = duration,
            label = text,
            useWhileDead = false,
            canCancel = canCancel,
            disable = {
                car = true,
                move = true,
                combat = true
            },
            anim = anim,
            prop = prop
        })
    end
end