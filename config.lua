Config = {}

---@class Drug
---@field price { min: number, max: number };
---@field amount { min: number, max: number } | number;

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
        }
    }
}