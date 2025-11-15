# REX Cooking - Installation & Feature Guide

**An advanced job-based cooking system with XP progression for RedM servers using RSG Framework**

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Core Features](#core-features)
4. [Configuration](#configuration)
5. [Server Integration](#server-integration)
6. [Database Setup](#database-setup)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Dependencies

- **rsg-core** - RSG Framework core
- **ox_lib** - OxLib library for UI and utilities
- **rsg-inventory** - RSG Inventory system
- **rsg-log** - RSG Logging system

### Framework Version

- **RedM** with Lua 5.4 support
- **RSG Framework** (Red Dead Survival Game Framework)

### Server Requirements

- Minimum 512MB free memory
- ~50ms average ping to database (recommended)

---

## Installation

### Step 1: Extract Resource

Extract the `rex-cooking` folder to your server's `resources` directory:

```
resources/
├── rsg-core/
├── ox_lib/
├── rsg-inventory/
└── rex-cooking/          ← Place here
```

### Step 2: Update server.cfg

Add the resource to your `server.cfg`:

```cfg
# Cooking System
ensure rsg-core
ensure ox_lib
ensure rsg-inventory
ensure rsg-log
ensure rex-cooking
```

**Important:** Load `rex-cooking` AFTER all dependencies.

### Step 3: Verify Installation

Start your server and check the console for:

```
[rex-cooking] Resource started successfully
```

If you see errors about missing dependencies, ensure all required resources are running.

---

## Core Features

### 1. **Cooking Locations & NPCs**

- NPC-based cooking stations at configured locations
- Automatic NPC spawning and despawning based on player proximity
- Interactive ox_target integration for easy access
- Customizable cooking location names and coordinates

**Default Location:**
- Valentine Cooking Station (coordinates: -315.41, 812.05, 118.98)

### 2. **Recipe System**

REX Cooking supports three recipe configuration modes:

#### Single Cooking Type Recipes
```lua
{
    category = 'Fish',
    cooktime = 10000,
    requiredxp = 0,
    xpreward = 1,
    requiredjob = nil,
    cookingtype = 'all',  -- Can cook anywhere
    ingredients = {
        { item = 'raw_fish', amount = 1 },
    },
    receive = 'cooked_fish',
    giveamount = 1
}
```

#### Job-Restricted Recipes
```lua
{
    category = 'Professional',
    cooktime = 30000,
    requiredxp = 50,
    xpreward = 10,
    requiredjob = 'cook',  -- Only 'cook' job
    cookingtype = 'cookjob',
    ingredients = {
        { item = 'raw_meat', amount = 2 },
        { item = 'flour_wheat', amount = 1 },
    },
    receive = 'gourmet_meal',
    giveamount = 1
}
```

#### Multiple Cooking Type Recipes
```lua
{
    category = 'Mixed',
    cooktime = 15000,
    requiredxp = 0,
    xpreward = 3,
    requiredjob = nil,
    cookingtype = {'stove', 'campfire'},  -- Table of types
    ingredients = {
        { item = 'raw_meat', amount = 1 },
    },
    receive = 'cooked_steak',
    giveamount = 1
}
```

### 3. **XP Progression System**

- Track cooking XP per player
- XP requirements for recipes
- XP rewards on successful cooking
- Configurable milestones (50, 100, 250, 500, 1000, 2500 XP)
- Automatic notifications on XP gains

**XP Tracking:**
- Data stored in RSG Framework reputation system
- Persists across server restarts
- Type: `'cooking'`

### 4. **Job-Based Cooking**

- Restrict recipes to specific jobs
- Job validation on cooking start
- Job requirement display in menus
- Support for universal recipes (no job requirement)

**Supported Job Types:**
- `nil` - No restriction (anyone can cook)
- `'cook'` - Chef/Cook job only
- Any custom job name configured in RSG Core

### 5. **Cooking Types**

Four cooking location types supported:

| Type | Description | Use Case |
|------|---|---|
| `'stove'` | NPC cooking stations | Standard cooking at stove locations |
| `'campfire'` | Campfire cooking | External campfire script integration |
| `'campsite'` | Campsite cooking | Campsite-specific recipes |
| `'cookjob'` | Job-specific kitchen | Job-restricted cooking areas |
| `'all'` | Anywhere | No location restriction |

### 6. **Discord Webhooks**

Comprehensive logging system with Discord integration:

- **Cooking Events**: Started, Completed, Cancelled, Failed
- **XP Events**: Gained, Milestone reached
- **Job Events**: Job restriction attempts
- **Admin Notifications**: Suspicious activity detection
- **Rate Limiting**: Prevent webhook spam

**Webhook Events:**
```
✅ Cooking Completed
⭐ XP Gained
🎉 XP Milestone Reached
🚫 Job Restriction
❌ Cooking Failed
```

### 7. **Player Menu System**

- Organized by recipe category
- Item images and metadata
- Ingredient list display
- XP requirement indicators
- Cooking time countdown

---

## Configuration

### Main Config (`shared/config.lua`)

#### Image Settings
```lua
Config.Image = "rsg-inventory/html/images/"  -- Inventory image path
```

#### NPC Spawn Settings
```lua
Config.DistanceSpawn = 20.0        -- Distance to spawn NPCs
Config.FadeIn = true               -- Fade animation on spawn
Config.BlipSprite = 935247438      -- Blip icon hash
Config.UpdateInterval = 1000       -- NPC distance check (ms)
Config.ModelTimeout = 5000         -- Model load timeout (ms)
Config.MaxConcurrentFades = 5      -- Max simultaneous fades
```

#### Target Integration
```lua
Config.EnableTarget = true  -- Enable ox_target for NPCs
```

#### Cooking Locations
```lua
Config.CookingLocations = {
    {
        name = 'Valentine Cooking',
        prompt = 'valcooking',
        coords = vec3(-315.41, 812.05, 118.98),
        npcmodel = `cs_mp_camp_cook`,
        npccoords = vec4(-315.41, 812.05, 118.98, 281.74),
        showblip = true
    },
    -- Add more locations as needed
}
```

#### Cooking Props
```lua
Config.CookingProps = {
    `p_stove01x`,
    `p_stove04x`,
    `p_stove05x`,
    -- Add more stove models
}
```

#### Cooking Types
```lua
Config.CookingTypes = {
    STOVE = 'stove',
    CAMPFIRE = 'campfire',
    CAMPSITE = 'campsite',
    COOKJOB = 'cookjob',
    ALL = 'all'
}
```

### Webhook Config (`shared/webhook_config.lua`)

#### Enable Webhooks
```lua
WebhookConfig.Enabled = true
WebhookConfig.WebhookURL = 'YOUR_DISCORD_WEBHOOK_URL'
```

#### Toggle Events
```lua
WebhookConfig.Events = {
    CookingStarted = true,
    CookingCompleted = true,
    CookingCancelled = true,
    CookingFailed = true,
    XPGained = true,
    XPMilestone = true,
    JobRestricted = true,
}
```

#### Detailed Logging
```lua
WebhookConfig.DetailedInfo = {
    ShowIngredients = true,
    ShowCookingType = true,
    ShowCookingTime = true,
    ShowXPReward = true,
    ShowPlayerJob = true,
    ShowLocation = true,
    ShowTimestamp = true,
}
```

#### XP Milestones
```lua
WebhookConfig.XPMilestones = {
    50, 100, 250, 500, 1000, 2500
}
```

---

## Server Integration

### Database Requirements

No custom database tables required. REX Cooking uses RSG Framework's built-in reputation system for XP storage.

**XP Type:** `'cooking'`

### Available Server Exports

#### Check Player Ingredients
```lua
local result = exports['rex-cooking']:CheckPlayerIngredients(playerId, ingredients)
-- Returns: { success = boolean, missingItems = {} }
```

#### Get/Give Cooking XP
```lua
local xp = exports['rex-cooking']:GetPlayerCookingXP(playerId)
exports['rex-cooking']:GivePlayerCookingXP(playerId, amount, xpType)
```

#### Process Cooking
```lua
local result = exports['rex-cooking']:ProcessCooking(playerId, cookData)
-- cookData = { ingredients = {}, receive = '', giveamount = 1, xpreward = 5 }
```

#### Get Recipes & Locations
```lua
local recipes = exports['rex-cooking']:GetCookingRecipes()
local locations = exports['rex-cooking']:GetCookingLocations()
```

#### Job-Based Exports
```lua
-- Check player job
local hasJob = exports['rex-cooking']:CheckPlayerJob(playerId, jobName)
local playerJob = exports['rex-cooking']:GetPlayerJob(playerId)

-- Get recipes by job
local jobRecipes = exports['rex-cooking']:GetRecipesByJob(jobName)

-- Process with job validation
local result = exports['rex-cooking']:ProcessCookingWithJobCheck(playerId, cookData)
```

#### Recipe Management
```lua
-- Check if item can be cooked
local canCook, recipe = exports['rex-cooking']:CanCookItem(itemName)

-- Get job requirement for recipe
local jobReq = exports['rex-cooking']:GetRecipeJobRequirement(itemName)

-- Add custom recipe at runtime
local success, msg = exports['rex-cooking']:AddCustomRecipe(recipeTable)
```

### Available Client Exports

```lua
-- Open cooking menu
exports['rex-cooking']:OpenCookingMenu()

-- Check proximity to cooking location
local isNear, locationData = exports['rex-cooking']:IsNearCookingLocation(distance)

-- Get cooking data
local locations = exports['rex-cooking']:GetCookingLocations()
local recipes = exports['rex-cooking']:GetCookingRecipes()
local categories = exports['rex-cooking']:GetCookingCategories()

-- Get recipe details
local recipe = exports['rex-cooking']:GetRecipeByItem(itemName)
local ingredients = exports['rex-cooking']:GetRecipeIngredients(itemName)
local typeRecipes = exports['rex-cooking']:GetRecipesByCookingType(cookingType)
```

---

## Database Setup

No database setup required for basic functionality. The system uses RSG Framework's reputation system.

### Optional: Custom Logging Table

To store cooking history in your own database:

```sql
CREATE TABLE IF NOT EXISTS `cooking_log` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `citizen_id` VARCHAR(50) NOT NULL,
  `player_name` VARCHAR(100),
  `item_cooked` VARCHAR(100),
  `quantity` INT(11),
  `xp_gained` INT(11),
  `job` VARCHAR(50),
  `location` VARCHAR(100),
  `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX (`citizen_id`),
  INDEX (`timestamp`)
);
```

---

## Troubleshooting

### Issue: "rsg-core not found"

**Solution:** Ensure `rsg-core` is loaded BEFORE `rex-cooking`.

```cfg
ensure rsg-core
ensure ox_lib
ensure rex-cooking  ← After rsg-core
```

### Issue: NPCs not spawning

**Cause:** Model loading timeout or NPC model not available.

**Solution:**
1. Check NPC model is valid: `cs_mp_camp_cook`
2. Increase `Config.ModelTimeout` in config.lua
3. Check player distance from NPC spawn location

### Issue: Items not appearing after cooking

**Cause:** Item not defined in RSG Shared Items or inventory full.

**Solution:**
1. Verify item exists: `/checkitem cooked_fish`
2. Clear player inventory slots
3. Check rsg-inventory resource is running

### Issue: Webhooks not sending

**Cause:** Invalid webhook URL or disabled events.

**Solution:**
1. Verify Discord webhook URL is correct
2. Set `WebhookConfig.Enabled = true`
3. Check specific event toggle: `WebhookConfig.Events.CookingCompleted = true`
4. Check server logs for webhook errors

### Issue: Job-restricted recipes not working

**Cause:** Job name mismatch or job validation failing.

**Solution:**
1. Verify job name matches RSG Framework: `/checkjob`
2. Check `requiredjob` field in recipe config
3. Ensure player has correct job set

### Issue: Cooking menu not appearing

**Cause:** Menu registration or target not working.

**Solution:**
1. Verify ox_target is running
2. Check console for menu registration errors
3. Ensure you're near a cooking location or NPC
4. Try `/cook` command if configured

### Debug Commands

Enable debug mode by adding to client script:

```lua
-- View all recipes
RegisterCommand('debugrecipes', function()
    local recipes = exports['rex-cooking']:GetCookingRecipes()
    print("^3Total recipes: " .. #recipes .. "^7")
    for _, r in ipairs(recipes) do
        print("  - " .. r.receive .. " (" .. r.category .. ")")
    end
end)

-- View player cooking XP
RegisterCommand('debugxp', function()
    local xp = exports['rex-cooking']:GetPlayerCookingXP(GetPlayerServerId(PlayerId()))
    print("^3Cooking XP: " .. xp .. "^7")
end)
```

---

## Support

For issues or feature requests, check:

1. **Console Logs** - Look for `[rex-cooking]` prefix messages
2. **Discord Webhook** - Check for error notifications
3. **Resource Status** - Verify all dependencies are running
4. **Configuration Files** - Ensure proper formatting in Lua files

---

## Version

- **Current Version:** 2.0.1
- **Framework:** RSG Framework
- **Lua Version:** 5.4
- **RedM Build:** Cerulean or higher

---

**Last Updated:** 2024
**Developed for RedM - Red Dead Redemption II FiveM alternative**
