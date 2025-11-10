local RSGCore = exports['rsg-core']:GetCoreObject()
local CategoryMenus = {}
local MenusRegistered = false
local isCooking = false
local playerXP = 0
local currentCookingType = 'stove' -- default to stove, can be changed by external scripts
lib.locale()

---------------------------------------------
-- target cooking props
---------------------------------------------
CreateThread(function()
    exports.ox_target:addModel(Config.CookingProps, {
        {
            name = 'cooking_props',
            icon = 'far fa-eye',
            label = locale('cl_lang_17'),
            onSelect = function()
                TriggerEvent('rex-cooking:client:cookingmenu', { cookingType = 'stove' })
            end,
            distance = 2.0
        }
    })
end)

---------------------------------------------
-- cookings menu
---------------------------------------------
local function BuildCookingMenus()
    CategoryMenus = {} -- Reset menus
    MenusRegistered = false -- Reset registration flag
    
    for _, v in ipairs(Config.Cooking) do
        local IngredientsMetadata = {}
        
        -- validate item exists before accessing
        local receivedItem = RSGCore.Shared.Items[tostring(v.receive)]
        if not receivedItem then
            print("^1[ERROR] Item '" .. tostring(v.receive) .. "' not found in RSGCore.Shared.Items^7")
            goto continue
        end
        
        local setheader = receivedItem.label
        local itemimg = "nui://"..Config.Image..receivedItem.image

        for i, ingredient in ipairs(v.ingredients) do
            local ingredientItem = RSGCore.Shared.Items[ingredient.item]
            if ingredientItem then
                table.insert(IngredientsMetadata, { label = ingredientItem.label, value = ingredient.amount })
            else
                print("^1[ERROR] Ingredient '" .. ingredient.item .. "' not found in RSGCore.Shared.Items^7")
            end
        end

        local option = {
            title = setheader,
            icon = itemimg,
            event = 'rex-cooking:client:cookitem',
            metadata = IngredientsMetadata,
            args = {
                title = setheader,
                category = v.category,
                ingredients = v.ingredients,
                cooktime = v.cooktime,
                requiredxp = v.requiredxp,
                xpreward = v.xpreward,
                receive = v.receive,
                giveamount = v.giveamount,
                requiredjob = v.requiredjob
            }
        }

        if not CategoryMenus[v.category] then
            CategoryMenus[v.category] = {
                id = 'cooking_menu_' .. v.category,
                title = v.category,
                menu = 'cooking_menu',
                onBack = function() end,
                options = { option }
            }
        else
            table.insert(CategoryMenus[v.category].options, option)
        end
        
        ::continue::
    end
end

-- build initial menus
CreateThread(function()
    BuildCookingMenus()
end)

-- register category events only once
local function RegisterCategoryMenus()
    if MenusRegistered then return end
    
    for category, MenuData in pairs(CategoryMenus) do
        RegisterNetEvent('rex-cooking:client:' .. category)
        AddEventHandler('rex-cooking:client:' .. category, function()
            lib.registerContext(MenuData)
            lib.showContext(MenuData.id)
        end)
    end
    
    MenusRegistered = true
end

-- register menus after they're built
CreateThread(function()
    Wait(100) -- Small delay to ensure CategoryMenus is populated
    RegisterCategoryMenus()
end)

-- get player's current cooking XP
local function UpdatePlayerXP()
    RSGCore.Functions.TriggerCallback('rex-cooking:server:checkxp', function(currentXP)
        playerXP = currentXP
    end, 'cooking')
end

-- update XP on script start
CreateThread(function()
    Wait(1000)
    UpdatePlayerXP()
end)
-- filter recipes based on player's job and cooking type
local function GetJobFilteredRecipes(cookingType)
    local filterType = cookingType or currentCookingType
    
    RSGCore.Functions.TriggerCallback('rex-cooking:server:getplayerjob', function(playerJob)
        RSGCore.Functions.TriggerCallback('rex-cooking:server:checkxp', function(currentXP)
            playerXP = currentXP
            
            local filteredCategoryMenus = {}
            
            -- Build all filtered category menus first
            for _, v in ipairs(Config.Cooking) do
                -- skip if recipe requires a job that player doesn't have
                if v.requiredjob and v.requiredjob ~= playerJob then
                    goto continue
                end
                
                -- skip if player doesn't have required XP
                local requiredXP = v.requiredxp or 0
                if currentXP < requiredXP then
                    goto continue
                end
                
                -- skip if recipe doesn't match cooking type
                local recipeCookingType = v.cookingtype or 'all'
                
                -- handle if cookingtype is a table (multiple types)
                if type(recipeCookingType) == 'table' then
                    local matchFound = false
                    for _, cType in ipairs(recipeCookingType) do
                        if cType == filterType or cType == 'all' then
                            matchFound = true
                            break
                        end
                    end
                    if not matchFound then
                        goto continue
                    end
                -- handle if cookingtype is a string (single type)
                elseif recipeCookingType ~= 'all' and recipeCookingType ~= filterType then
                    goto continue
                end
                
                local IngredientsMetadata = {}
                
                -- Validate item exists before accessing
                local receivedItem = RSGCore.Shared.Items[tostring(v.receive)]
                if not receivedItem then
                    goto continue
                end
                
                local setheader = receivedItem.label
                local itemimg = "nui://"..Config.Image..receivedItem.image

                for i, ingredient in ipairs(v.ingredients) do
                    local ingredientItem = RSGCore.Shared.Items[ingredient.item]
                    if ingredientItem then
                        table.insert(IngredientsMetadata, { 
                            label = ingredientItem.label, 
                            value = ingredient.amount 
                        })
                    end
                end
                
                -- add XP information to metadata
                if v.requiredxp and v.requiredxp > 0 then
                    table.insert(IngredientsMetadata, { 
                        label = locale('cl_lang_19'), 
                        value = v.requiredxp 
                    })
                end
                
                if v.xpreward and v.xpreward > 0 then
                    table.insert(IngredientsMetadata, { 
                        label = locale('cl_lang_20'), 
                        value = v.xpreward 
                    })
                end
                
                if v.requiredjob then
                    table.insert(IngredientsMetadata, { 
                        label = locale('cl_lang_21'), 
                        value = v.requiredjob 
                    })
                end

                local option = {
                    title = setheader,
                    icon = itemimg,
                    event = 'rex-cooking:client:cookitem',
                    metadata = IngredientsMetadata,
                    args = {
                        title = setheader,
                        category = v.category,
                        ingredients = v.ingredients,
                        cooktime = v.cooktime,
                        requiredxp = v.requiredxp,
                        xpreward = v.xpreward,
                        receive = v.receive,
                        giveamount = v.giveamount,
                        requiredjob = v.requiredjob,
                        cookingtype = v.cookingtype
                    }
                }

                -- Properly accumulate recipes in their categories
                if not filteredCategoryMenus[v.category] then
                    filteredCategoryMenus[v.category] = {
                        id = 'cooking_menu_' .. v.category,
                        title = v.category,
                        menu = 'cooking_menu',
                        onBack = function() end,
                        options = { option }
                    }
                else
                    table.insert(filteredCategoryMenus[v.category].options, option)
                end
                
                ::continue::
            end
            
            -- Register filtered category menus once after all recipes are processed
            for category, MenuData in pairs(filteredCategoryMenus) do
                RegisterNetEvent('rex-cooking:client:' .. category)
                AddEventHandler('rex-cooking:client:' .. category, function()
                    lib.registerContext(MenuData)
                    lib.showContext(MenuData.id)
                end)
            end

            -- show main menu with XP display and cooking type
            local cookingTypeLabel = 'Stove'
            if filterType == 'campfire' then
                cookingTypeLabel = 'Campfire'
            elseif filterType == 'campsite' then
                cookingTypeLabel = 'Campsite'
            elseif filterType == 'cookjob' then
                cookingTypeLabel = 'Job Kitchen'
            end

            local Menu = {
                id = 'cooking_menu',
                title = locale('cl_lang_3') .. ' (' .. cookingTypeLabel .. ')',
                description = string.format(locale('cl_lang_18'), playerXP),
                options = {}
            }

            -- sort categories alphabetically
            local sortedCategories = {}
            for category, MenuData in pairs(filteredCategoryMenus) do
                table.insert(sortedCategories, {name = category, data = MenuData})
            end
            table.sort(sortedCategories, function(a, b) return a.name < b.name end)
            
            for _, cat in ipairs(sortedCategories) do
                table.insert(Menu.options, {
                    title = cat.name,
                    event = 'rex-cooking:client:' .. cat.name,
                    arrow = true,
                    icon = 'fa-solid fa-fire'
                })
            end

            if #Menu.options == 0 then
                lib.notify({ title = locale('cl_lang_11'), description = locale('cl_lang_12'), type = 'inform', duration = 5000 })
                return
            end

            lib.registerContext(Menu)
            lib.showContext(Menu.id)
        end, 'cooking')
    end)
end

RegisterNetEvent('rex-cooking:client:cookingmenu', function(data)
    local cookingType = data and data.cookingType or 'stove'
    currentCookingType = cookingType
    GetJobFilteredRecipes(cookingType)
end)

---------------------------------------------
-- cook item
---------------------------------------------
RegisterNetEvent('rex-cooking:client:cookitem', function(data)
    -- prevent multiple cooking at once
    if isCooking then
        lib.notify({ 
            title = locale('cl_lang_25'), 
            description = locale('cl_lang_26'), 
            type = 'inform', 
            duration = 3000 
        })
        return
    end
    RSGCore.Functions.TriggerCallback('rex-cooking:server:checkxp', function(currentXP)
        if currentXP >= (data.requiredxp or 0) then
            -- check cooking items and job requirements
            RSGCore.Functions.TriggerCallback('rex-cooking:server:checkingredients', function(result)
                if result.jobRestricted then
                    lib.notify({ 
                        title = locale('cl_lang_13'), 
                        description = string.format(locale('cl_lang_14'), result.requiredJob), 
                        type = 'error', 
                        duration = 7000 
                    })
                    return
                elseif result.success == true then
                    isCooking = true
                    LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
                    
                    -- Trigger webhook for cooking started
                    TriggerServerEvent('rex-cooking:server:cookingstarted', data)
                    
                    -- validate item exists before accessing
                    local itemData = RSGCore.Shared.Items[data.receive]
                    if not itemData then
                        print("^1[ERROR] Cooked item '" .. data.receive .. "' not found in RSGCore.Shared.Items^7")
                        LocalPlayer.state:set("inv_busy", false, true)
                        return
                    end
                    
                    local success = lib.progressBar({
                        duration = tonumber(data.cooktime),
                        position = 'bottom',
                        useWhileDead = false,
                        canCancel = true,
                        disableControl = true,
                        disable = {
                            move = true,
                            mouse = true,
                        },
                        label = locale('cl_lang_4').. itemData.label,
                        anim = {
                            dict = 'amb_work@world_human_bartender@serve_player',
                            clip = 'take_glass_trans_pour_beer_hold'
                        },
                    })
                    
                    if success then
                        TriggerServerEvent('rex-cooking:server:finishcooking', data)
                        
                        -- show success notification
                        lib.notify({ 
                            title = locale('cl_lang_23'), 
                            description = string.format(locale('cl_lang_24'), data.giveamount, itemData.label), 
                            type = 'success', 
                            duration = 5000 
                        })
                        
                        -- update XP after cooking
                        Wait(500)
                        UpdatePlayerXP()
                    else
                        -- Trigger webhook for cooking cancelled
                        TriggerServerEvent('rex-cooking:server:cookingcancelled', data)
                        
                        lib.notify({ 
                            title = locale('cl_lang_27'), 
                            description = locale('cl_lang_28'), 
                            type = 'inform', 
                            duration = 3000 
                        })
                    end
                    
                    isCooking = false
                    LocalPlayer.state:set("inv_busy", false, true) -- unlock inventory
                else
                    -- Show detailed missing items notification
                    local function ShowMissingItemsNotification(missingItems)
                        if not missingItems or #missingItems == 0 then
                            lib.notify({ title = locale('cl_lang_5'), type = 'error', duration = 7000 })
                            return
                        end
                        
                        local missingText = locale('cl_lang_8') .. "\n"
                        
                        for i, missing in ipairs(missingItems) do
                            if missing.have > 0 then
                                -- player has some but not enough
                                missingText = missingText .. string.format(locale('cl_lang_9'), missing.missing, missing.label, missing.have, missing.need)
                            else
                                -- player has none
                                missingText = missingText .. string.format(locale('cl_lang_10'), missing.need, missing.label)
                            end
                            
                            if i < #missingItems then
                                missingText = missingText .. "\n"
                            end
                        end
                        
                        lib.notify({ 
                            description = missingText, 
                            type = 'error', 
                            duration = 10000 -- Longer duration for detailed info
                        })
                    end
                    
                    -- Trigger webhook for cooking failed
                    TriggerServerEvent('rex-cooking:server:cookingfailed', data, result.missingItems)
                    
                    ShowMissingItemsNotification(result.missingItems)
                end
            end, data.ingredients, data.requiredjob)
        else
            local requiredXP = data.requiredxp or 0
            lib.notify({ 
                title = locale('cl_lang_15'), 
                description = string.format(locale('cl_lang_16'), requiredXP, currentXP), 
                type = 'error', 
                duration = 7000 
            })
        end
    end, 'cooking')
end)

---------------------------------------------
-- CLIENT EXPORTS
---------------------------------------------

-- open cooking menu programmatically
-- @param cookingType string - 'stove', 'campfire', 'campsite', 'cookjob', or nil (defaults to 'stove')
exports('OpenCookingMenu', function(cookingType)
    local cookType = cookingType or 'stove'
    TriggerEvent('rex-cooking:client:cookingmenu', { cookingType = cookType })
end)

-- check if player is near a cooking location
exports('IsNearCookingLocation', function(maxDistance)
    local playerCoords = GetEntityCoords(cache.ped)
    local checkDistance = maxDistance or Config.DistanceSpawn
    
    for k, v in pairs(Config.CookingLocations) do
        local distance = #(playerCoords - v.coords)
        if distance <= checkDistance then
            return true, {
                id = k,
                name = v.name,
                coords = v.coords,
                distance = distance
            }
        end
    end
    
    return false, nil
end)

-- get all cooking locations
exports('GetCookingLocations', function()
    return Config.CookingLocations
end)

-- get cooking recipes by category
exports('GetCookingRecipes', function(category)
    if not category then
        return Config.Cooking
    end
    
    local recipes = {}
    for _, recipe in ipairs(Config.Cooking) do
        if recipe.category == category then
            table.insert(recipes, recipe)
        end
    end
    
    return recipes
end)

-- get all available categories
exports('GetCookingCategories', function()
    local categories = {}
    local seen = {}
    
    for _, recipe in ipairs(Config.Cooking) do
        if not seen[recipe.category] then
            table.insert(categories, recipe.category)
            seen[recipe.category] = true
        end
    end
    
    return categories
end)

-- check if a specific recipe exists
exports('GetRecipeByItem', function(itemName)
    for _, recipe in ipairs(Config.Cooking) do
        if recipe.receive == itemName then
            return recipe
        end
    end
    
    return nil
end)

-- get recipe ingredients with labels
exports('GetRecipeIngredients', function(itemName)
    local recipe = exports['rex-cooking']:GetRecipeByItem(itemName)
    if not recipe then return nil end
    
    local ingredients = {}
    for _, ingredient in ipairs(recipe.ingredients) do
        local itemData = RSGCore.Shared.Items[ingredient.item]
        table.insert(ingredients, {
            item = ingredient.item,
            amount = ingredient.amount,
            label = itemData and itemData.label or ingredient.item
        })
    end
    
    return ingredients
end)

-- get recipes by cooking type
-- @param cookingType string - 'stove', 'campfire', 'campsite', 'cookjob', or 'all'
-- @return table - array of recipes that can be cooked with the specified type
exports('GetRecipesByCookingType', function(cookingType)
    if not cookingType then return Config.Cooking end
    
    local recipes = {}
    for _, recipe in ipairs(Config.Cooking) do
        local recipeCookingType = recipe.cookingtype or 'all'
        
        -- handle if cookingtype is a table (multiple types)
        if type(recipeCookingType) == 'table' then
            for _, cType in ipairs(recipeCookingType) do
                if cType == 'all' or cType == cookingType then
                    table.insert(recipes, recipe)
                    break
                end
            end
        -- handle if cookingtype is a string (single type)
        elseif recipeCookingType == 'all' or recipeCookingType == cookingType then
            table.insert(recipes, recipe)
        end
    end
    
    return recipes
end)
