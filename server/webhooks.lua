local RSGCore = exports['rsg-core']:GetCoreObject()

---------------------------------
-- webhook rate limiting
---------------------------------
local webhookQueue = {}
local webhookCount = 0
local lastResetTime = os.time()

local function ResetRateLimit()
    local currentTime = os.time()
    if currentTime - lastResetTime >= 60 then
        webhookCount = 0
        lastResetTime = currentTime
    end
end

local function CanSendWebhook()
    if not WebhookConfig.RateLimit.Enabled then
        return true
    end
    
    ResetRateLimit()
    return webhookCount < WebhookConfig.RateLimit.MaxPerMinute
end

---------------------------------
-- player milestone tracking
---------------------------------
local playerMilestones = {}

local function HasReachedMilestone(source, milestone)
    if not playerMilestones[source] then
        playerMilestones[source] = {}
    end
    return playerMilestones[source][milestone] == true
end

local function MarkMilestone(source, milestone)
    if not playerMilestones[source] then
        playerMilestones[source] = {}
    end
    playerMilestones[source][milestone] = true
end

---------------------------------
-- get player information
---------------------------------
local function GetPlayerInfo(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if not Player then return nil end
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    local info = {
        name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        citizenid = Player.PlayerData.citizenid,
        job = Player.PlayerData.job.label or 'Unemployed',
        jobName = Player.PlayerData.job.name or 'unemployed',
        grade = Player.PlayerData.job.grade.name or 'N/A',
        coords = coords,
        location = string.format('X: %.2f, Y: %.2f, Z: %.2f', coords.x, coords.y, coords.z),
        source = source,
    }
    
    return info
end

---------------------------------
-- format ingredients list
---------------------------------
local function FormatIngredients(ingredients)
    if not ingredients then return 'N/A' end
    
    local list = {}
    for _, ingredient in ipairs(ingredients) do
        local itemData = RSGCore.Shared.Items[ingredient.item]
        local itemName = itemData and itemData.label or ingredient.item
        table.insert(list, string.format('%dx %s', ingredient.amount, itemName))
    end
    
    return table.concat(list, ', ')
end

---------------------------------
-- format cooking type
---------------------------------
local function FormatCookingType(cookingType)
    if not cookingType then return 'Unknown' end
    
    if type(cookingType) == 'table' then
        local types = {}
        for _, cType in ipairs(cookingType) do
            table.insert(types, cType:sub(1,1):upper() .. cType:sub(2))
        end
        return table.concat(types, ' / ')
    else
        return cookingType:sub(1,1):upper() .. cookingType:sub(2)
    end
end

---------------------------------
-- format time
---------------------------------
local function FormatTime(ms)
    if not ms then return 'N/A' end
    local seconds = math.floor(ms / 1000)
    if seconds < 60 then
        return seconds .. ' seconds'
    else
        local minutes = math.floor(seconds / 60)
        local remainingSeconds = seconds % 60
        return string.format('%d min %d sec', minutes, remainingSeconds)
    end
end

---------------------------------
-- send webhook
---------------------------------
local function SendWebhook(webhookURL, embeds)
    if not webhookURL or webhookURL == '' then return end
    if not CanSendWebhook() then 
        print('^3[rex-cooking] Webhook rate limit reached, skipping webhook^7')
        return 
    end
    
    local payload = json.encode({
        username = 'REX Cooking',
        avatar_url = '',
        embeds = embeds
    })
    
    PerformHttpRequest(webhookURL, function(err, text, headers)
        if err ~= 200 and err ~= 204 then
            print('^1[rex-cooking] Webhook error: ' .. tostring(err) .. '^7')
        else
            webhookCount = webhookCount + 1
        end
    end, 'POST', payload, {['Content-Type'] = 'application/json'})
end

---------------------------------
-- build embed
---------------------------------
local function BuildEmbed(template, fields, description)
    local embed = {
        title = template.title,
        color = template.color,
        description = description or '',
        fields = fields or {},
        timestamp = WebhookConfig.DetailedInfo.ShowTimestamp and os.date('!%Y-%m-%dT%H:%M:%SZ') or nil,
        footer = {
            text = WebhookConfig.Footer.Text,
            icon_url = WebhookConfig.Footer.IconURL ~= '' and WebhookConfig.Footer.IconURL or nil
        }
    }
    
    if WebhookConfig.Thumbnail.Enabled and WebhookConfig.Thumbnail.DefaultURL ~= '' then
        embed.thumbnail = {
            url = WebhookConfig.Thumbnail.DefaultURL
        }
    end
    
    return embed
end

---------------------------------
-- webhook functions
---------------------------------

function SendCookingStartedWebhook(source, recipeData)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.CookingStarted then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local itemData = RSGCore.Shared.Items[recipeData.receive]
    local itemName = itemData and itemData.label or recipeData.receive
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'Item', value = itemName, inline = true},
    }
    
    if WebhookConfig.DetailedInfo.ShowPlayerJob then
        table.insert(fields, {name = 'Job', value = playerInfo.job .. ' (' .. playerInfo.grade .. ')', inline = true})
    end
    
    if WebhookConfig.DetailedInfo.ShowCookingType then
        table.insert(fields, {name = 'Cooking Type', value = FormatCookingType(recipeData.cookingtype), inline = true})
    end
    
    if WebhookConfig.DetailedInfo.ShowCookingTime then
        table.insert(fields, {name = 'Cook Time', value = FormatTime(recipeData.cooktime), inline = true})
    end
    
    if WebhookConfig.DetailedInfo.ShowIngredients then
        table.insert(fields, {name = 'Ingredients', value = FormatIngredients(recipeData.ingredients), inline = false})
    end
    
    if WebhookConfig.DetailedInfo.ShowLocation then
        table.insert(fields, {name = 'Location', value = playerInfo.location, inline = false})
    end
    
    local description = string.format('**%s** started cooking **%s**', playerInfo.name, itemName)
    local embed = BuildEmbed(WebhookConfig.Templates.CookingStarted, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

function SendCookingCompletedWebhook(source, recipeData)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.CookingCompleted then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local itemData = RSGCore.Shared.Items[recipeData.receive]
    local itemName = itemData and itemData.label or recipeData.receive
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'Item Received', value = string.format('%dx %s', recipeData.giveamount, itemName), inline = true},
    }
    
    if WebhookConfig.DetailedInfo.ShowPlayerJob then
        table.insert(fields, {name = 'Job', value = playerInfo.job .. ' (' .. playerInfo.grade .. ')', inline = true})
    end
    
    if WebhookConfig.DetailedInfo.ShowXPReward and recipeData.xpreward then
        table.insert(fields, {name = 'XP Gained', value = '+' .. recipeData.xpreward .. ' XP', inline = true})
    end
    
    if WebhookConfig.DetailedInfo.ShowCookingType then
        table.insert(fields, {name = 'Cooking Type', value = FormatCookingType(recipeData.cookingtype), inline = true})
    end
    
    if WebhookConfig.DetailedInfo.ShowLocation then
        table.insert(fields, {name = 'Location', value = playerInfo.location, inline = false})
    end
    
    local description = string.format('**%s** successfully cooked **%dx %s**', playerInfo.name, recipeData.giveamount, itemName)
    local embed = BuildEmbed(WebhookConfig.Templates.CookingCompleted, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

function SendCookingCancelledWebhook(source, recipeData)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.CookingCancelled then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local itemData = RSGCore.Shared.Items[recipeData.receive]
    local itemName = itemData and itemData.label or recipeData.receive
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'Item', value = itemName, inline = true},
    }
    
    if WebhookConfig.DetailedInfo.ShowLocation then
        table.insert(fields, {name = 'Location', value = playerInfo.location, inline = false})
    end
    
    local description = string.format('**%s** cancelled cooking **%s**', playerInfo.name, itemName)
    local embed = BuildEmbed(WebhookConfig.Templates.CookingCancelled, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

function SendCookingFailedWebhook(source, recipeData, missingItems)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.CookingFailed then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local itemData = RSGCore.Shared.Items[recipeData.receive]
    local itemName = itemData and itemData.label or recipeData.receive
    
    local missingList = {}
    for _, missing in ipairs(missingItems) do
        table.insert(missingList, string.format('%dx %s', missing.missing, missing.label))
    end
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'Attempted Item', value = itemName, inline = true},
        {name = 'Missing Items', value = table.concat(missingList, ', '), inline = false},
    }
    
    if WebhookConfig.DetailedInfo.ShowLocation then
        table.insert(fields, {name = 'Location', value = playerInfo.location, inline = false})
    end
    
    local description = string.format('**%s** failed to cook **%s** - Missing ingredients', playerInfo.name, itemName)
    local embed = BuildEmbed(WebhookConfig.Templates.CookingFailed, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

function SendXPGainedWebhook(source, xpGained, newTotal)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.XPGained then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'XP Gained', value = '+' .. xpGained .. ' XP', inline = true},
        {name = 'Total XP', value = newTotal .. ' XP', inline = true},
    }
    
    -- Check for level up (simulated)
    if WebhookConfig.Events.LevelUpSimulated then
        local oldLevel = math.floor((newTotal - xpGained) / 50)
        local newLevel = math.floor(newTotal / 50)
        if newLevel > oldLevel then
            table.insert(fields, {name = 'Level Up!', value = 'Level ' .. oldLevel .. ' → Level ' .. newLevel, inline = true})
        end
    end
    
    local description = string.format('**%s** gained **%d XP** in cooking', playerInfo.name, xpGained)
    local embed = BuildEmbed(WebhookConfig.Templates.XPGained, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

function SendXPMilestoneWebhook(source, milestone, totalXP)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.XPMilestone then return end
    if HasReachedMilestone(source, milestone) then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    MarkMilestone(source, milestone)
    
    local milestoneRank = 'Unknown'
    if milestone == 50 then milestoneRank = 'Beginner Cook'
    elseif milestone == 100 then milestoneRank = 'Amateur Cook'
    elseif milestone == 250 then milestoneRank = 'Skilled Cook'
    elseif milestone == 500 then milestoneRank = 'Expert Cook'
    elseif milestone == 1000 then milestoneRank = 'Master Cook'
    elseif milestone == 2500 then milestoneRank = 'Grand Master Cook'
    end
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'Milestone', value = milestone .. ' XP', inline = true},
        {name = 'Rank Achieved', value = milestoneRank, inline = true},
        {name = 'Total XP', value = totalXP .. ' XP', inline = true},
    }
    
    local description = string.format('🎉 **%s** reached **%d XP** milestone and became a **%s**!', playerInfo.name, milestone, milestoneRank)
    local embed = BuildEmbed(WebhookConfig.Templates.XPMilestone, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

function SendJobRestrictedWebhook(source, recipeData, requiredJob)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.JobRestricted then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local itemData = RSGCore.Shared.Items[recipeData.receive]
    local itemName = itemData and itemData.label or recipeData.receive
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'Player Job', value = playerInfo.job, inline = true},
        {name = 'Required Job', value = requiredJob, inline = true},
        {name = 'Attempted Item', value = itemName, inline = true},
    }
    
    if WebhookConfig.DetailedInfo.ShowLocation then
        table.insert(fields, {name = 'Location', value = playerInfo.location, inline = false})
    end
    
    local description = string.format('**%s** tried to cook **%s** but lacks required job: **%s**', playerInfo.name, itemName, requiredJob)
    local embed = BuildEmbed(WebhookConfig.Templates.JobRestricted, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

function SendRecipeUnlockWebhook(source, recipeName, requiredXP, currentXP)
    if not WebhookConfig.Enabled or not WebhookConfig.Events.RecipeUnlock then return end
    
    local playerInfo = GetPlayerInfo(source)
    if not playerInfo then return end
    
    local fields = {
        {name = 'Player', value = playerInfo.name, inline = true},
        {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
        {name = 'Recipe Unlocked', value = recipeName, inline = true},
        {name = 'Required XP', value = requiredXP .. ' XP', inline = true},
        {name = 'Current XP', value = currentXP .. ' XP', inline = true},
    }
    
    local description = string.format('**%s** unlocked a new recipe: **%s**!', playerInfo.name, recipeName)
    local embed = BuildEmbed(WebhookConfig.Templates.RecipeUnlock, fields, description)
    
    SendWebhook(WebhookConfig.WebhookURL, {embed})
end

---------------------------------
-- admin notifications
---------------------------------
function SendAdminNotification(title, description, fields, color)
    if not WebhookConfig.AdminNotifications.Enabled then return end
    if not WebhookConfig.AdminNotifications.WebhookURL or WebhookConfig.AdminNotifications.WebhookURL == '' then return end
    
    local embed = {
        title = '⚠️ ' .. title,
        color = color or WebhookConfig.Colors.Warning,
        description = description,
        fields = fields or {},
        timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
        footer = {
            text = 'REX Cooking - Admin Alert',
        }
    }
    
    SendWebhook(WebhookConfig.AdminNotifications.WebhookURL, {embed})
end

function CheckSuspiciousActivity(source, xpGained)
    if not WebhookConfig.AdminNotifications.NotifyOnHighXP then return end
    
    if xpGained >= WebhookConfig.AdminNotifications.HighXPThreshold then
        local playerInfo = GetPlayerInfo(source)
        if not playerInfo then return end
        
        SendAdminNotification(
            'High XP Gain Detected',
            string.format('Player **%s** gained **%d XP** in a single cooking action', playerInfo.name, xpGained),
            {
                {name = 'Player', value = playerInfo.name, inline = true},
                {name = 'Citizen ID', value = playerInfo.citizenid, inline = true},
                {name = 'XP Gained', value = xpGained .. ' XP', inline = true},
                {name = 'Location', value = playerInfo.location, inline = false},
            },
            WebhookConfig.Colors.Warning
        )
    end
end

---------------------------------
-- cleanup on player drop
---------------------------------
AddEventHandler('playerDropped', function()
    local source = source
    if playerMilestones[source] then
        playerMilestones[source] = nil
    end
end)

print('^2[rex-cooking] Webhook system loaded^7')
