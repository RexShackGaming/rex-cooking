-- =====================================================
-- CAMPFIRE & CAMPSITE COOKING INTEGRATION EXAMPLE
-- =====================================================
-- This example shows how external scripts can integrate
-- with rex-cooking to provide campfire and campsite cooking
-- =====================================================

-- Example 1: Using ox_target with a campfire prop
-- Add this to your campfire script's client-side code
CreateThread(function()
    -- List of campfire props (add your campfire models here)
    local campfireProps = {
        `p_campfire01x`,
        `p_campfire02x`,
        `p_campfire03x`,
        `p_campfire04x`,
        `p_campfire05x`,
        `p_campfire06x`,
        `p_gen_campfire01x`,
    }
    
    -- Add ox_target interaction to campfire props
    exports.ox_target:addModel(campfireProps, {
        {
            name = 'campfire_cooking',
            icon = 'fa-solid fa-fire',
            label = 'Cook at Campfire',
            onSelect = function()
                -- Open rex-cooking menu with 'campfire' type
                exports['rex-cooking']:OpenCookingMenu('campfire')
            end,
            distance = 2.5
        }
    })
end)

-- =====================================================
-- Example 2: Proximity-based campfire detection
-- =====================================================
-- Use this if you want to detect when player is near a campfire

local function IsNearCampfire()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local campfireProps = {
        `p_campfire01x`,
        `p_campfire02x`,
        `p_campfire03x`,
        `p_campfire04x`,
        `p_campfire05x`,
        `p_campfire06x`,
        `p_gen_campfire01x`,
    }
    
    for _, model in ipairs(campfireProps) do
        local campfire = GetClosestObjectOfType(playerCoords.x, playerCoords.y, playerCoords.z, 3.0, model, false, false, false)
        if campfire ~= 0 then
            return true, campfire
        end
    end
    
    return false, nil
end

-- Example command to open campfire cooking menu when near a campfire
RegisterCommand('cookcampfire', function()
    local nearCampfire, campfireEntity = IsNearCampfire()
    
    if nearCampfire then
        exports['rex-cooking']:OpenCookingMenu('campfire')
    else
        -- Notify player they're not near a campfire
        lib.notify({
            title = 'Campfire Required',
            description = 'You need to be near a campfire to cook!',
            type = 'error',
            duration = 3000
        })
    end
end, false)

-- =====================================================
-- Example 3: Custom campfire placement system integration
-- =====================================================
-- If your script allows players to place campfires

RegisterNetEvent('yourcampfire:client:placed')
AddEventHandler('yourcampfire:client:placed', function(campfireEntity)
    -- When a campfire is placed, add cooking interaction to it
    exports.ox_target:addLocalEntity(campfireEntity, {
        {
            name = 'placed_campfire_cooking',
            icon = 'fa-solid fa-fire',
            label = 'Cook at Campfire',
            onSelect = function()
                exports['rex-cooking']:OpenCookingMenu('campfire')
            end,
            distance = 2.5
        }
    })
end)

-- =====================================================
-- Example 4: Get available campfire recipes
-- =====================================================
-- If you want to display what can be cooked at a campfire

RegisterCommand('campfirerecipes', function()
    -- Get all recipes available for campfire cooking
    local campfireRecipes = exports['rex-cooking']:GetRecipesByCookingType('campfire')
    
    print('^3=== CAMPFIRE RECIPES ===^7')
    print('^2Available campfire recipes: ' .. #campfireRecipes .. '^7')
    
    for _, recipe in ipairs(campfireRecipes) do
        local cookingType = recipe.cookingtype or 'all'
        print('  - ' .. recipe.receive .. ' (' .. recipe.category .. ') [' .. cookingType .. ']')
    end
    print('^3========================^7')
end, false)

-- =====================================================
-- Example 5: Integration with fire warmth/survival systems
-- =====================================================
-- If you have a survival system that requires campfires

RegisterNetEvent('yoursurvival:client:nearcampfire')
AddEventHandler('yoursurvival:client:nearcampfire', function(isLit)
    if isLit then
        -- Show notification that cooking is available
        lib.notify({
            title = 'Campfire',
            description = 'Press [E] to cook food at the campfire',
            type = 'inform',
            duration = 5000
        })
        
        -- You could also add a keybind here to open cooking menu
    end
end)

-- =====================================================
-- Example 6: Standalone campfire cooking zones
-- =====================================================
-- Create specific zones for campfire cooking (e.g., at campsites)

local campfireZones = {
    -- Example: Big Valley campsite
    {
        coords = vec3(-1241.32, -342.19, 91.41),
        radius = 3.0,
        blip = true,
        name = "Big Valley Campfire"
    },
    -- Example: Heartlands campsite
    {
        coords = vec3(467.83, 546.92, 109.98),
        radius = 3.0,
        blip = true,
        name = "Heartlands Campfire"
    },
    -- Add more zones as needed
}

-- Create blips for campfire zones
CreateThread(function()
    for _, zone in ipairs(campfireZones) do
        if zone.blip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, `blip_campfire`, true)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, zone.name)
        end
    end
end)

-- Check if player is in a campfire zone
CreateThread(function()
    while true do
        Wait(1000)
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, zone in ipairs(campfireZones) do
            local distance = #(playerCoords - zone.coords)
            if distance <= zone.radius then
                -- Player is in campfire zone
                -- You could show a prompt here or use ox_target
            end
        end
    end
end)

-- =====================================================
-- Example 7: Event-based campfire cooking
-- =====================================================
-- Trigger cooking from your own script's events

RegisterNetEvent('yourcampfire:client:startcooking')
AddEventHandler('yourcampfire:client:startcooking', function()
    -- Validate player is near a heat source first
    local nearCampfire, _ = IsNearCampfire()
    
    if nearCampfire then
        exports['rex-cooking']:OpenCookingMenu('campfire')
    else
        lib.notify({
            title = 'No Heat Source',
            description = 'You need to be near a campfire to cook!',
            type = 'error',
            duration = 3000
        })
    end
end)

-- =====================================================
-- Example 8: Campsite-specific cooking integration
-- =====================================================
-- Use this for dedicated campsite setups with more equipment

local campsiteProps = {
    `p_camp_fire_lrg01x`, -- Large campfire
    `mp005_p_mp_campfire01x`, -- Camp setup
}

CreateThread(function()
    exports.ox_target:addModel(campsiteProps, {
        {
            name = 'campsite_cooking',
            icon = 'fa-solid fa-campground',
            label = 'Cook at Campsite',
            onSelect = function()
                -- Open rex-cooking menu with 'campsite' type
                exports['rex-cooking']:OpenCookingMenu('campsite')
            end,
            distance = 3.0
        }
    })
end)

-- Get campsite-specific recipes
RegisterCommand('campsiterecipes', function()
    local campsiteRecipes = exports['rex-cooking']:GetRecipesByCookingType('campsite')
    
    print('^3=== CAMPSITE RECIPES ===^7')
    print('^2Available campsite recipes: ' .. #campsiteRecipes .. '^7')
    
    for _, recipe in ipairs(campsiteRecipes) do
        local cookingType = recipe.cookingtype or 'all'
        print('  - ' .. recipe.receive .. ' (' .. recipe.category .. ') [' .. cookingType .. ']')
    end
    print('^3========================^7')
end, false)

-- =====================================================
-- NOTES FOR INTEGRATION:
-- =====================================================
-- 1. To use external cooking, recipes in Config.Cooking must have:
--    cookingtype = 'campfire', 'campsite', 'cookjob', or 'all'
--
-- 2. To make a recipe ONLY available at campfires:
--    cookingtype = 'campfire'
--
-- 3. To make a recipe ONLY available at campsites:
--    cookingtype = 'campsite'
--
-- 4. To make a recipe ONLY available at job-specific locations:
--    cookingtype = 'cookjob' (must also set requiredjob)
--
-- 5. To make a recipe available at all cooking locations:
--    cookingtype = 'all'
--
-- 6. To make a recipe ONLY available at NPC stoves:
--    cookingtype = 'stove'
--
-- 7. The cooking menu will automatically filter recipes based
--    on the cooking type passed to OpenCookingMenu()
--
-- 8. Use 'campfire' for basic wilderness cooking
--    Use 'campsite' for more elaborate camp setups
--    Use 'cookjob' for professional/job-restricted cooking
--
-- 9. MIXED COOKING TYPES (multiple specific locations):
--    You can use an array to specify multiple cooking types:
--    
--    cookingtype = {'stove', 'campfire'}  -- Works at stoves OR campfires only
--    cookingtype = {'campfire', 'campsite'}  -- Outdoor cooking only
--    cookingtype = {'stove', 'cookjob'}  -- Indoor kitchens only
--    
--    This gives fine-grained control without using 'all'
-- =====================================================

-- =====================================================
-- Example 9: Job-specific cooking location integration
-- =====================================================
-- Use this for job-restricted cooking areas (e.g., saloon kitchen, restaurant)

local jobCookingLocations = {
    {
        coords = vec3(-312.73, 805.54, 118.98), -- Valentine Saloon kitchen
        job = 'cook',
        blip = false,
        name = "Saloon Kitchen"
    },
    {
        coords = vec3(2930.34, 520.87, 45.35), -- Saint Denis Restaurant
        job = 'chef',
        blip = false,
        name = "Restaurant Kitchen"
    },
}

-- Add ox_target zones for job-specific cooking
CreateThread(function()
    for _, location in ipairs(jobCookingLocations) do
        exports.ox_target:addSphereZone({
            coords = location.coords,
            radius = 2.5,
            options = {
                {
                    name = 'job_cooking_' .. location.job,
                    icon = 'fa-solid fa-utensils',
                    label = 'Use Professional Kitchen',
                    onSelect = function()
                        -- Open rex-cooking menu with 'cookjob' type
                        exports['rex-cooking']:OpenCookingMenu('cookjob')
                    end,
                    canInteract = function()
                        -- Only show to players with the required job
                        local Player = exports['rsg-core']:GetCoreObject().Functions.GetPlayerData()
                        return Player.job and Player.job.name == location.job
                    end,
                    distance = 2.5
                }
            }
        })
    end
end)

-- Example: Job-specific cooking stove prop
local professionalStoveProps = {
    `p_stove02x`, -- Professional stove model
}

CreateThread(function()
    exports.ox_target:addModel(professionalStoveProps, {
        {
            name = 'professional_cooking',
            icon = 'fa-solid fa-fire-burner',
            label = 'Professional Cooking',
            onSelect = function()
                exports['rex-cooking']:OpenCookingMenu('cookjob')
            end,
            canInteract = function()
                -- Check if player has a cooking-related job
                local Player = exports['rsg-core']:GetCoreObject().Functions.GetPlayerData()
                local cookingJobs = {'cook', 'chef', 'baker'}
                if Player.job then
                    for _, job in ipairs(cookingJobs) do
                        if Player.job.name == job then
                            return true
                        end
                    end
                end
                return false
            end,
            distance = 2.0
        }
    })
end)

-- Get job-specific recipes
RegisterCommand('jobrecipes', function()
    local jobRecipes = exports['rex-cooking']:GetRecipesByCookingType('cookjob')
    
    print('^3=== JOB-SPECIFIC RECIPES ===^7')
    print('^2Available job recipes: ' .. #jobRecipes .. '^7')
    
    for _, recipe in ipairs(jobRecipes) do
        local requiredJob = recipe.requiredjob or 'none'
        print('  - ' .. recipe.receive .. ' (Job: ' .. requiredJob .. ')')
    end
    print('^3============================^7')
end, false)

print('^2[rex-cooking] Campfire integration examples loaded^7')
