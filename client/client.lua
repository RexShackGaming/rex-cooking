local RSGCore = exports['rsg-core']:GetCoreObject()
local CategoryMenus = {}
local MenusRegistered = false
lib.locale()

-- add target here

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
                maketime = v.maketime,
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

-- filter recipes based on player's job
local function GetJobFilteredRecipes()
    RSGCore.Functions.TriggerCallback('rex-cooking:server:getplayerjob', function(playerJob)
        local filteredCategoryMenus = {}
        
        for _, v in ipairs(Config.Cooking) do
            -- skip if recipe requires a job that player doesn't have
            if v.requiredjob and v.requiredjob ~= playerJob then
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
                    table.insert(IngredientsMetadata, { label = ingredientItem.label, value = ingredient.amount })
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
        
        -- register filtered menus
        for category, MenuData in pairs(filteredCategoryMenus) do
            RegisterNetEvent('rex-cooking:client:' .. category)
            AddEventHandler('rex-cooking:client:' .. category, function()
                lib.registerContext(MenuData)
                lib.showContext(MenuData.id)
            end)
        end
        
        -- show main menu
        local Menu = {
            id = 'cooking_menu',
            title = locale('cl_lang_3'),
            options = {}
        }

        for category, MenuData in pairs(filteredCategoryMenus) do
            table.insert(Menu.options, {
                title = category,
                event = 'rex-cooking:client:' .. category,
                arrow = true
            })
        end

        if #Menu.options == 0 then
            lib.notify({ title = 'No Recipes Available', description = 'You don\'t have access to any cooking recipes.', type = 'inform', duration = 5000 })
            return
        end

        lib.registerContext(Menu)
        lib.showContext(Menu.id)
    end)
end

RegisterNetEvent('rex-cooking:client:cookingmenu', function()
    GetJobFilteredRecipes()
end)

---------------------------------------------
-- cook item
---------------------------------------------
RegisterNetEvent('rex-cooking:client:cookitem', function(data)
    RSGCore.Functions.TriggerCallback('rex-cooking:server:checkxp', function(currentXP)
        if currentXP >= (data.requiredxp or 0) then
            -- check cooking items and job requirements
            RSGCore.Functions.TriggerCallback('rex-cooking:server:checkingredients', function(result)
                if result.jobRestricted then
                    lib.notify({ 
                        title = 'Job Required', 
                        description = 'You need to be a ' .. result.requiredJob .. ' to cook this item.', 
                        type = 'error', 
                        duration = 7000 
                    })
                    return
                elseif result.success == true then
                    LocalPlayer.state:set("inv_busy", true, true) -- lock inventory
                    
                    -- validate item exists before accessing
                    local itemData = RSGCore.Shared.Items[data.receive]
                    if not itemData then
                        print("^1[ERROR] Cooked item '" .. data.receive .. "' not found in RSGCore.Shared.Items^7")
                        LocalPlayer.state:set("inv_busy", false, true)
                        return
                    end
                    
                    local success = lib.progressBar({
                        duration = tonumber(data.crafttime),
                        position = 'bottom',
                        useWhileDead = false,
                        canCancel = true,
                        disableControl = true,
                        disable = {
                            move = true,
                            mouse = true,
                        },
                        label = locale('cl_lang_4').. itemData.label,
                    })
                    
                    if success then
                        TriggerServerEvent('rex-cooking:server:finishcooking', data)
                    end
                    
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
                    
                    ShowMissingItemsNotification(result.missingItems)
                end
            end, data.ingredients, data.requiredjob)
        else
            local requiredXP = data.requiredxp or 0
            lib.notify({ 
                title = 'Insufficient Experience', 
                description = 'You need ' .. requiredXP .. ' XP to cook this item. Current XP: ' .. currentXP, 
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
exports('OpenCookingMenu', function()
    TriggerEvent('rex-cooking:client:cookingmenu')
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
