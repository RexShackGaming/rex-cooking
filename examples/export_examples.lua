-- Example script demonstrating rex-cooking exports
-- This file shows how other resources can integrate with rex-cooking

print("^2=== REX-COOKING EXPORTS EXAMPLES ===^7")

-- CLIENT-SIDE EXAMPLES (use in client scripts)
if IsDuplicityVersion() == false then -- Client-side only
    
    print("^3--- CLIENT EXPORTS EXAMPLES ---^7")
    
    -- Example 1: Check if player is near crafting location
    CreateThread(function()
        while true do
            Wait(5000) -- Check every 5 seconds
            
            local isNear, locationData = exports['rex-cooking']:IsNearCookingLocation(25.0)
            if isNear then
                print("^2Player is near: " .. locationData.name .. " (Distance: " .. math.floor(locationData.distance) .. "m)^7")
            end
        end
    end)
    
    -- Example 2: Get all cooking categories
    local function ShowCookingInfo()
        local categories = exports['rex-cooking']:GetCookingCategories()
        print("^3Available cooking categories:^7")
        for _, category in ipairs(categories) do
            print("  - " .. category)
            
            -- Get recipes in this category
            local recipes = exports['rex-cooking']:GetCookingRecipes(category)
            for _, recipe in ipairs(recipes) do
                print("    → " .. recipe.receive .. " (requires " .. #recipe.ingredients .. " ingredients)")
            end
        end
    end
    
    -- Example 3: Custom command to show cooking info
    RegisterCommand('cookinginfo', function()
        ShowCookingInfo()
    end, false)
    
    -- Example 4: Custom command to open cooking menu anywhere
    RegisterCommand('cook', function()
        exports['rex-cooking']:OpenCookingMenu()
    end, false)
    
    -- Example 5: Get recipe details
    RegisterCommand('cookingrecipe', function(source, args)
        if not args[1] then
            print("^1Usage: /recipe <item_name>^7")
            return
        end
        
        local itemName = args[1]
        local recipe = exports['rex-cooking']:GetRecipeByItem(itemName)
        
        if recipe then
            print("^2Recipe found for " .. itemName .. ":^7")
            print("  Category: " .. recipe.category)
            print("  Cook time: " .. recipe.cooktime .. "ms")
            print("  Required XP: " .. (recipe.requiredxp or 0))
            print("  XP reward: " .. (recipe.xpreward or 0))
            
            local ingredients = exports['rex-cooking']:GetRecipeIngredients(itemName)
            print("  Ingredients:")
            for _, ingredient in ipairs(ingredients) do
                print("    - " .. ingredient.amount .. "x " .. ingredient.label)
            end
        else
            print("^1No recipe found for " .. itemName .. "^7")
        end
    end, false)
    
end

-- SERVER-SIDE EXAMPLES (use in server scripts)
if IsDuplicityVersion() then -- Server-side only
    
    print("^3--- SERVER EXPORTS EXAMPLES ---^7")
    
    -- Example 1: Check player ingredients command
    RegisterCommand('checkingredients', function(source, args)
        if source == 0 then return end -- Console only
        
        -- Example ingredients to check
        local testIngredients = {
            { item = 'coal', amount = 5 },
            { item = 'steel_bar', amount = 2 }
        }
        
        local result = exports['rex-crafting']:CheckPlayerIngredients(source, testIngredients)
        
        if result.success then
            print("^2Player " .. source .. " has all required ingredients^7")
        else
            print("^1Player " .. source .. " is missing ingredients:^7")
            for _, missing in ipairs(result.missingItems) do
                print("  - " .. missing.missing .. "x " .. missing.label .. " (has " .. missing.have .. "/" .. missing.need .. ")")
            end
        end
    end, true)
    
    -- Example 2: Give crafting XP command
    RegisterCommand('givecraftxp', function(source, args)
        if source ~= 0 then return end -- Console only
        
        local targetId = tonumber(args[1])
        local xpAmount = tonumber(args[2]) or 10
        
        if not targetId then
            print("Usage: givecraftxp <player_id> [amount]")
            return
        end
        
        local success = exports['rex-crafting']:GivePlayerCraftingXP(targetId, xpAmount)
        if success then
            print("^2Gave " .. xpAmount .. " crafting XP to player " .. targetId .. "^7")
        else
            print("^1Failed to give XP to player " .. targetId .. "^7")
        end
    end, true)
    
    -- Example 3: Add custom recipe at runtime
    local function AddExampleRecipe()
        local customRecipe = {
            category = 'Examples',
            crafttime = 15000,
            craftingxp = 5,
            bpc = 'bpc_example_item',
            ingredients = {
                { item = 'coal', amount = 2 },
                { item = 'wood', amount = 3 }
            },
            receive = 'example_crafted_item',
            giveamount = 1
        }
        
        local success, message = exports['rex-crafting']:AddCustomRecipe(customRecipe)
        print("^3Custom recipe result: " .. message .. "^7")
    end
    
    -- Add the custom recipe when resource starts
    CreateThread(function()
        Wait(5000) -- Wait for rex-crafting to fully load
        AddExampleRecipe()
    end)
    
    -- Example 4: External crafting system
    RegisterNetEvent('example:craft-external')
    AddEventHandler('example:craft-external', function(itemName)
        local source = source
        
        -- Check if item can be crafted
        local canCraft, recipe = exports['rex-crafting']:CanCraftItem(itemName)
        
        if not canCraft then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1Error', 'No recipe exists for ' .. itemName }
            })
            return
        end
        
        -- Use the ProcessCrafting export to handle everything
        local result = exports['rex-crafting']:ProcessCrafting(source, recipe)
        
        if result.success then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^2Success', 'Crafted ' .. itemName .. ' successfully!' }
            })
        else
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1Error', 'Crafting failed: ' .. result.error }
            })
        end
    end)
    
    -- Example 5: Get player's current crafting level
    RegisterCommand('craftlevel', function(source, args)
        if source == 0 then return end
        
        local xp = exports['rex-crafting']:GetPlayerCraftingXP(source)
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^3Crafting', 'Your crafting XP: ' .. xp }
        })
    end, false)
    
    -- JOB-BASED CRAFTING EXAMPLES
    
    -- Example 6: Check player's job
    RegisterCommand('checkjob', function(source, args)
        if source == 0 then return end
        
        local playerJob = exports['rex-crafting']:GetPlayerJob(source)
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^3Job Check', 'Your current job: ' .. (playerJob or 'unemployed') }
        })
    end, false)
    
    -- Example 7: Check if player can craft specific item
    RegisterCommand('canjob', function(source, args)
        if source == 0 then return end
        
        if not args[1] then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1Error', 'Usage: /canjob <item_name>' }
            })
            return
        end
        
        local itemName = args[1]
        local requiredJob = exports['rex-crafting']:GetRecipeJobRequirement(itemName)
        
        if not requiredJob then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^2Success', 'No job requirement for ' .. itemName }
            })
        else
            local canCraft = exports['rex-crafting']:CheckPlayerJob(source, requiredJob)
            local playerJob = exports['rex-crafting']:GetPlayerJob(source)
            
            if canCraft then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^2Success', 'You can craft ' .. itemName .. ' (requires: ' .. requiredJob .. ')' }
                })
            else
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^1Error', 'You cannot craft ' .. itemName .. '. Required: ' .. requiredJob .. ', Your job: ' .. (playerJob or 'unemployed') }
                })
            end
        end
    end, false)
    
    -- Example 8: Get recipes available to player's job
    RegisterCommand('jobrecipes', function(source, args)
        if source == 0 then return end
        
        local playerJob = exports['rex-crafting']:GetPlayerJob(source)
        local availableRecipes = exports['rex-crafting']:GetRecipesByJob(playerJob)
        
        TriggerClientEvent('chat:addMessage', source, {
            args = { '^3Job Recipes', 'Available recipes for ' .. (playerJob or 'unemployed') .. ': ' .. #availableRecipes }
        })
        
        for i, recipe in ipairs(availableRecipes) do
            if i <= 5 then -- Show only first 5 to avoid spam
                local jobText = recipe.requiredjob and ' (Job: ' .. recipe.requiredjob .. ')' or ' (No job req)'
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '', '  - ' .. recipe.receive .. jobText }
                })
            end
        end
        
        if #availableRecipes > 5 then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '', '  ... and ' .. (#availableRecipes - 5) .. ' more' }
            })
        end
    end, false)
    
    -- Example 9: Enhanced external crafting with job check
    RegisterNetEvent('example:craft-job-restricted')
    AddEventHandler('example:craft-job-restricted', function(itemName)
        local source = source
        
        -- Check if item can be crafted
        local canCraft, recipe = exports['rex-crafting']:CanCraftItem(itemName)
        
        if not canCraft then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^1Error', 'No recipe exists for ' .. itemName }
            })
            return
        end
        
        -- Use the enhanced ProcessCraftingWithJobCheck export
        local result = exports['rex-crafting']:ProcessCraftingWithJobCheck(source, recipe)
        
        if result.success then
            TriggerClientEvent('chat:addMessage', source, {
                args = { '^2Success', 'Crafted ' .. itemName .. ' successfully!' }
            })
        else
            if result.error == 'Job requirement not met' then
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^1Job Required', 'You need to be a ' .. result.requiredJob .. ' to craft this item. Your job: ' .. (result.playerJob or 'unemployed') }
                })
            else
                TriggerClientEvent('chat:addMessage', source, {
                    args = { '^1Error', 'Crafting failed: ' .. result.error }
                })
            end
        end
    end)
    
    -- Example 10: Add custom job-restricted recipe
    local function AddBlacksmithRecipe()
        local blacksmithRecipe = {
            category = 'Blacksmith Specials',
            crafttime = 60000,
            requiredxp = 150,    -- Need 150 XP to craft this advanced item
            xpreward = 20,       -- Gain 20 XP after crafting
            requiredjob = 'blacksmith', -- Only blacksmiths can craft this
            ingredients = {
                { item = 'coal', amount = 10 },
                { item = 'steel_bar', amount = 5 }
            },
            receive = 'custom_blacksmith_hammer',
            giveamount = 1
        }
        
        local success, message = exports['rex-crafting']:AddCustomRecipe(blacksmithRecipe)
        print("^3Custom blacksmith recipe result: " .. message .. "^7")
    end
    
    -- Add the custom blacksmith recipe when resource starts
    CreateThread(function()
        Wait(5000) -- Wait for rex-crafting to fully load
        AddBlacksmithRecipe()
    end)
    
end

print("^2=== EXPORT EXAMPLES LOADED ===^7")
