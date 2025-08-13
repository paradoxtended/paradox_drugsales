1. Install these dependecies: 
    ox_lib - https://github.com/overextended/ox_lib/releases/latest/download/ox_lib.zip 
    ox_target - https://github.com/overextended/ox_target
    prp_lib - https://github.com/paradoxtended/prp_lib

2. Ensure the resource in server.cfg
3. Copy and paste images into ox_inventory/web/build/images
4. Add this to ox_inventory/data/items.lua (Optional depends on whether you want to have predefined drugs or make your owns,
   rarity define only if you are using prp_inventory - https://github.com/paradoxtended/prp-inventory):
    ['drug_phone'] = { label = 'Drug Phone', stack = false, weight = 100, rarity = 'uncommon' },
    ['meth_bag'] = { label = 'Meth bag', stack = true, weight = 10, rarity = 'rare' },
	['coke_bag'] = { label = 'Coke bag', stack = true, weight = 10, rarity = 'epic' },
    ['heroin_bag'] = { label = 'Heroing bag', stack = true, weight = 10, rarity = 'rare' },
    ['weed_bag'] = { label = 'Weed bag', stack = true, weight = 10, rarity = 'uncommon' },
    ['weed_joint'] = { label = 'Weed joint', stack = true, weight = 10, rarity = 'uncommon' }