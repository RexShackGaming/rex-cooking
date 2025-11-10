local RSGCore = exports['rsg-core']:GetCoreObject()
lib.locale()

---------------------------------------------
-- job validation function
---------------------------------------------
local function CheckPlayerJobRequirement(source, requiredJob)
    if not requiredJob then
        return true
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        return false
    end
    
    local playerJob = Player.PlayerData.job.type
    return playerJob == requiredJob
end

---------------------------------------------
-- increase xp function
---------------------------------------------
local function IncreasePlayerXP(source, xpGain, xpType)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Add XP incrementally
    Player.Functions.AddRep(xpType, xpGain)
    
    TriggerClientEvent('ox_lib:notify', source, { 
        title = string.format(locale('sv_lang_3'), xpGain, xpType), 
        type = 'inform', 
        duration = 7000 
    })
    
    return true
end

---------------------------------------------
-- get player job
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-cooking:server:getplayerjob', function(source, cb)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb(nil)
        return
    end
    
    local playerJob = Player.PlayerData.job.type
    cb(playerJob)
end)

---------------------------------------------
-- check player job permission
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-cooking:server:checkjob', function(source, cb, requiredJob)
    local hasPermission = CheckPlayerJobRequirement(source, requiredJob)
    cb(hasPermission)
end)

---------------------------------------------
-- check player xp
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-cooking:server:checkxp', function(source, cb, xptype)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb(0)
        return
    end
    
    local currentXP = Player.Functions.GetRep(xptype) or 0
    cb(currentXP)
end)

---------------------------------------------
-- check player has the ingredients
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-cooking:server:checkingredients', function(source, cb, ingredients, requiredJob)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        cb({ success = false, missingItems = {}, jobRestricted = false })
        return
    end
    
    if not ingredients or #ingredients == 0 then
        cb({ success = false, missingItems = {}, jobRestricted = false })
        return
    end
    
    -- check job requirement first
    if requiredJob and not CheckPlayerJobRequirement(source, requiredJob) then
        -- Webhook: Job restriction
        if SendJobRestrictedWebhook then
            -- Note: recipeData will need to be passed from client in future
            SendJobRestrictedWebhook(source, {receive = 'unknown'}, requiredJob)
        end
        cb({ success = false, missingItems = {}, jobRestricted = true, requiredJob = requiredJob })
        return
    end
    
    local missingItems = {}
    
    -- check all ingredients and collect missing items info
    for _, ingredient in ipairs(ingredients) do
        local itemCount = exports['rsg-inventory']:GetItemCount(source, ingredient.item)
        local needed = ingredient.amount
        
        if itemCount < needed then
            local itemData = RSGCore.Shared.Items[ingredient.item]
            local itemLabel = itemData and itemData.label or ingredient.item
            
            table.insert(missingItems, {
                item = ingredient.item,
                label = itemLabel,
                have = itemCount,
                need = needed,
                missing = needed - itemCount
            })
        end
    end
    
    if #missingItems > 0 then
        cb({ success = false, missingItems = missingItems, jobRestricted = false })
    else
        cb({ success = true, missingItems = {}, jobRestricted = false })
    end
end)

---------------------------------------------
-- finish cooking / give item
---------------------------------------------
RegisterNetEvent('rex-cooking:server:finishcooking', function(data)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- validate data
    if not data or not data.ingredients or not data.receive or not data.giveamount then
        print("^1[ERROR] Invalid cooking data received from player " .. src .. "^7")
        return
    end
    
    -- check job requirement
    if data.requiredjob and not CheckPlayerJobRequirement(src, data.requiredjob) then
        print("^1[WARNING] Player " .. src .. " tried to cook an item requiring job '" .. data.requiredjob .. "' but doesn't have the required job^7")
        TriggerClientEvent('ox_lib:notify', src, { 
            title = locale('sv_lang_4'), 
            description = string.format(locale('sv_lang_5'), data.requiredjob), 
            type = 'error', 
            duration = 7000 
        })
        return
    end
    
    -- double-check ingredients before processing (using same logic as callback)
    local missingItems = {}
    for _, ingredient in ipairs(data.ingredients) do
        local itemCount = exports['rsg-inventory']:GetItemCount(src, ingredient.item)
        if itemCount < ingredient.amount then
            local itemData = RSGCore.Shared.Items[ingredient.item]
            local itemLabel = itemData and itemData.label or ingredient.item
            table.insert(missingItems, { item = ingredient.item, label = itemLabel })
        end
    end
    
    if #missingItems > 0 then
        local itemNames = {}
        for _, missing in ipairs(missingItems) do
            table.insert(itemNames, missing.label)
        end
        print("^1[WARNING] Player " .. src .. " tried to cook without sufficient items: " .. table.concat(itemNames, ", ") .. "^7")
        return
    end

    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    local receive = data.receive
    local giveamount = data.giveamount
    
    -- remove ingredients
    for _, ingredient in ipairs(data.ingredients) do
        local success = Player.Functions.RemoveItem(ingredient.item, ingredient.amount)
        if success then
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[ingredient.item], 'remove', ingredient.amount)
        else
            print("^1[ERROR] Failed to remove ingredient " .. ingredient.item .. " from player " .. src .. "^7")
            return
        end
    end
    
    -- add cooked item
    local itemAdded = Player.Functions.AddItem(receive, giveamount)
    if itemAdded then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[receive], 'add', giveamount)
    else
        print("^1[ERROR] Failed to add cooked item " .. receive .. " to player " .. src .. "^7")
        return
    end
    
    -- use configured XP reward value
    local xpGain = data.xpreward or 1
    IncreasePlayerXP(src, xpGain, 'cooking')
    
    -- get current XP for webhooks
    local currentXP = Player.Functions.GetRep('cooking') or 0
    
    -- Webhook: Cooking completed
    if SendCookingCompletedWebhook then
        SendCookingCompletedWebhook(src, data)
    end
    
    -- Webhook: XP gained
    if SendXPGainedWebhook then
        SendXPGainedWebhook(src, xpGain, currentXP)
    end
    
    -- Webhook: Check for XP milestones
    if SendXPMilestoneWebhook and WebhookConfig and WebhookConfig.XPMilestones then
        for _, milestone in ipairs(WebhookConfig.XPMilestones) do
            if currentXP >= milestone and (currentXP - xpGain) < milestone then
                SendXPMilestoneWebhook(src, milestone, currentXP)
            end
        end
    end
    
    -- Webhook: Check for suspicious XP gains
    if CheckSuspiciousActivity then
        CheckSuspiciousActivity(src, xpGain)
    end
    
    -- log the cooking event
    TriggerEvent('rsg-log:server:CreateLog', 'cooking', locale('sv_lang_1'), 'green', firstname..' '..lastname..' ('..citizenid..locale('sv_lang_2')..RSGCore.Shared.Items[receive].label)
end)

---------------------------------------------
-- webhook event handlers
---------------------------------------------
RegisterNetEvent('rex-cooking:server:cookingstarted', function(data)
    local src = source
    if SendCookingStartedWebhook then
        SendCookingStartedWebhook(src, data)
    end
end)

RegisterNetEvent('rex-cooking:server:cookingcancelled', function(data)
    local src = source
    if SendCookingCancelledWebhook then
        SendCookingCancelledWebhook(src, data)
    end
end)

RegisterNetEvent('rex-cooking:server:cookingfailed', function(data, missingItems)
    local src = source
    if SendCookingFailedWebhook then
        SendCookingFailedWebhook(src, data, missingItems)
    end
end)

---------------------------------------------
-- SERVER EXPORTS
---------------------------------------------

-- check if player has required ingredients for a recipe
exports('CheckPlayerIngredients', function(source, ingredients)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then 
        return { success = false, missingItems = {} }
    end
    
    if not ingredients or #ingredients == 0 then
        return { success = false, missingItems = {} }
    end
    
    local missingItems = {}
    
    for _, ingredient in ipairs(ingredients) do
        local itemCount = exports['rsg-inventory']:GetItemCount(source, ingredient.item)
        local needed = ingredient.amount
        
        if itemCount < needed then
            local itemData = RSGCore.Shared.Items[ingredient.item]
            local itemLabel = itemData and itemData.label or ingredient.item
            
            table.insert(missingItems, {
                item = ingredient.item,
                label = itemLabel,
                have = itemCount,
                need = needed,
                missing = needed - itemCount
            })
        end
    end
    
    if #missingItems > 0 then
        return { success = false, missingItems = missingItems }
    else
        return { success = true, missingItems = {} }
    end
end)

-- get player's cooking XP
exports('GetPlayerCookingXP', function(source, xpType)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return 0 end
    
    xpType = xpType or 'cooking'
    return Player.Functions.GetRep(xpType) or 0
end)

-- add XP to player (for external cooking systems)
exports('GivePlayerCookingXP', function(source, xpGain, xpType)
    xpType = xpType or 'cooking'
    return IncreasePlayerXP(source, xpGain, xpType)
end)

-- process cooking for external systems
exports('ProcessCooking', function(source, cookData)
    -- validate required fields
    local requiredFields = {'ingredients', 'receive', 'giveamount'}
    for _, field in ipairs(requiredFields) do
        if not cookData[field] then
            return { success = false, error = 'Missing required field: ' .. field }
        end
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        return { success = false, error = 'Player not found' }
    end
    
    -- check ingredients
    local ingredientCheck = exports['rex-cooking']:CheckPlayerIngredients(source, cookData.ingredients)
    if not ingredientCheck.success then
        return { success = false, error = 'Missing ingredients', missingItems = ingredientCheck.missingItems }
    end
    
    -- remove ingredients
    for _, ingredient in ipairs(cookData.ingredients) do
        local success = Player.Functions.RemoveItem(ingredient.item, ingredient.amount)
        if not success then
            return { success = false, error = 'Failed to remove ingredient: ' .. ingredient.item }
        end
        TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[ingredient.item], 'remove', ingredient.amount)
    end
    
    -- add cooked item
    local itemAdded = Player.Functions.AddItem(cookData.receive, cookData.giveamount)
    if not itemAdded then
        -- try to restore ingredients on failure
        for _, ingredient in ipairs(cookData.ingredients) do
            Player.Functions.AddItem(ingredient.item, ingredient.amount)
        end
        return { success = false, error = 'Failed to add cooked item' }
    end
    
    TriggerClientEvent('rsg-inventory:client:ItemBox', source, RSGCore.Shared.Items[cookData.receive], 'add', cookData.giveamount)
    
    -- add XP if specified
    if cookData.xpreward and cookData.xpreward > 0 then
        IncreasePlayerXP(source, cookData.xpreward, 'cooking')
    end
    
    -- log the cooking event
    local citizenid = Player.PlayerData.citizenid
    local firstname = Player.PlayerData.charinfo.firstname
    local lastname = Player.PlayerData.charinfo.lastname
    
    TriggerEvent('rsg-log:server:CreateLog', 'cooking', 'External Cooking', 'blue', firstname..' '..lastname..' ('..citizenid..') cooked '..cookData.giveamount..'x '..RSGCore.Shared.Items[cookData.receive].label)
    
    return { success = true }
end)

-- get all cooking recipes (server-side access)
exports('GetCookingRecipes', function()
    return Config.Cooking
end)

-- get cooking locations (server-side access)
exports('GetCookingLocations', function()
    return Config.CookingLocations
end)

-- check if an item can be cooked
exports('CanCookItem', function(itemName)
    for _, recipe in ipairs(Config.Cooking) do
        if recipe.receive == itemName then
            return true, recipe
        end
    end
    
    return false, nil
end)

-- check if player has required job for cooking
exports('CheckPlayerJob', function(source, requiredJob)
    return CheckPlayerJobRequirement(source, requiredJob)
end)

-- get player's current job
exports('GetPlayerJob', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    return Player.PlayerData.job.type
end)

-- check if a recipe requires a specific job
exports('GetRecipeJobRequirement', function(itemName)
    for _, recipe in ipairs(Config.Cooking) do
        if recipe.receive == itemName then
            return recipe.requiredjob
        end
    end
    
    return nil
end)

-- get all recipes available to a specific job
exports('GetRecipesByJob', function(jobName)
    local jobRecipes = {}
    
    for _, recipe in ipairs(Config.Cooking) do
        -- include recipes with no job requirement or matching job requirement
        if not recipe.requiredjob or recipe.requiredjob == jobName then
            table.insert(jobRecipes, recipe)
        end
    end
    
    return jobRecipes
end)

-- Enhanced ProcessCooking with job validation
exports('ProcessCookingWithJobCheck', function(source, cookData)
    -- validate required fields
    local requiredFields = {'ingredients', 'receive', 'giveamount'}
    for _, field in ipairs(requiredFields) do
        if not cookData[field] then
            return { success = false, error = 'Missing required field: ' .. field }
        end
    end
    
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then
        return { success = false, error = 'Player not found' }
    end
    
    -- Check job requirement
    if cookData.requiredjob and not CheckPlayerJobRequirement(source, cookData.requiredjob) then
        return { 
            success = false, 
            error = 'Job requirement not met', 
            requiredJob = cookData.requiredjob,
            playerJob = Player.PlayerData.job.type
        }
    end
    
    -- Use existing ProcessCooking logic
    return exports['rex-cooking']:ProcessCooking(source, cookData)
end)

-- Add custom recipe at runtime (for dynamic systems)
exports('AddCustomRecipe', function(recipe)
    -- Validate required fields
    local requiredFields = {'category', 'cooktime', 'ingredients', 'receive', 'giveamount'}
    for _, field in ipairs(requiredFields) do
        if not recipe[field] then
            return false, 'Missing required field: ' .. field
        end
    end
    
    -- Handle backward compatibility with old cookingxp field
    if recipe.cookingxp and not recipe.xpreward then
        recipe.xpreward = recipe.cookingxp
    end
    if recipe.cookingxp and not recipe.requiredxp then
        recipe.requiredxp = recipe.cookingxp
    end
    
    -- Check if item already has a recipe
    for _, existingRecipe in ipairs(Config.Cooking) do
        if existingRecipe.receive == recipe.receive then
            return false, 'Recipe already exists for item: ' .. recipe.receive
        end
    end
    
    table.insert(Config.Cooking, recipe)
    return true, 'Recipe added successfully'
end)
