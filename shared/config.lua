Config = {}

---------------------------------
-- settings
---------------------------------
Config.Image = "rsg-inventory/html/images/"
Config.Keybind = 'J'
Config.EnableTarget = true

---------------------------------
-- npc settings
---------------------------------
Config.DistanceSpawn = 20.0
Config.FadeIn = true

---------------------------------
-- optimization settings
---------------------------------
Config.UpdateInterval = 1000  -- NPC distance check interval (ms)
Config.ModelTimeout = 5000    -- Model loading timeout (ms)
Config.MaxConcurrentFades = 5 -- Maximum simultaneous fade animations

---------------------------------
-- npc locations
---------------------------------
Config.CookingLocations = {
    {
        name = 'Valentine Cooking',
        prompt = 'valcooking',
        coords = vector3(-369.83, 798.21, 116.19),
        npcmodel = `mp_u_M_M_lom_rhd_smithassistant_01`,
        npccoords = vector4(-369.83, 798.21, 116.19, 225.12),
        showblip = true
    },
}

---------------------------------
-- cooking items
---------------------------------
Config.Cooking = {
    {
        category = 'Tools',
        crafttime = 30000,
        requiredxp = 0,      -- XP required to cook this item
        xpreward = 5,        -- XP gained after successful cooking
        requiredjob = nil,   -- nil means no job restriction (anyone can cook)
        ingredients = {
            { item = 'coal',      amount = 1 },
            { item = 'steel_bar', amount = 1 },
            { item = 'wood',      amount = 1 },
        },
        receive = 'pickaxe',
        giveamount = 1
    },
    {
        category = 'Blacksmith',
        crafttime = 45000,
        requiredxp = 0,
        xpreward = 5,
        requiredjob = 'blacksmith', -- Only jobtype blacksmith can cook this
        ingredients = {
            { item = 'coal',      amount = 1 },
            { item = 'steel_bar', amount = 1 },
        },
        receive = 'weapon_melee_knife',
        giveamount = 1
    },
    -- add more as required
}
