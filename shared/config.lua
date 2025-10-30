Config = {}

---------------------------------
-- settings
---------------------------------
Config.Image = "rsg-inventory/html/images/"
Config.EnableTarget = true  -- Enable ox_target for NPCs

---------------------------------
-- npc settings
---------------------------------
Config.DistanceSpawn = 20.0
Config.FadeIn = true
Config.BlipSprite = -1749618580 -- cooking pot icon

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
-- cooking props
---------------------------------
Config.CookingProps = {
    `p_stove01x`,
    `p_stove04x`,
    `p_stove05x`,
    `p_stove06x`,
    `p_stove07x`,
    `p_stove09x`,
}

---------------------------------
-- cooking items
---------------------------------
Config.Cooking = {

    ------------------------------------------
	-- fish recipes
    ------------------------------------------
    {
        category = 'Fish',
        cooktime = 10000,
        requiredxp = 0,      -- XP required to cook this item
        xpreward = 1,        -- XP gained after successful cooking
        requiredjob = nil,   -- nil means no job restriction (anyone can cook)
        ingredients = {
            { item = 'raw_fish', amount = 1 },
        },
        receive = 'cooked_fish',
        giveamount = 1
    },
    ------------------------------------------
	-- meat recipes
    ------------------------------------------
    {
        category = 'Meat',
        cooktime = 10000,
        requiredxp = 0,
        xpreward = 1,
        requiredjob = nil,
        ingredients = {
            { item = 'raw_meat', amount = 1 },
        },
        receive = 'cooked_meat',
        giveamount = 1
    },
    ------------------------------------------
	-- bread recipes
    ------------------------------------------
    {
        category = 'Bread',
        cooktime = 25000,
        requiredxp = 0,
        xpreward = 2,
        requiredjob = nil,
        ingredients = {
            { item = 'flour_wheat', amount = 2 },
            { item = 'milk',        amount = 1 },
            { item = 'egg',         amount = 1 },
        },
        receive = 'bread_sour',
        giveamount = 2
    },

}
