# Cooking Types Feature

## Overview
The rex-cooking script now supports different cooking types, allowing you to distinguish between cooking at NPC stoves and cooking at campfires (or other external heat sources).

## Cooking Types

### Available Types
- **`stove`** - Cooking at NPC locations with stoves (default)
- **`campfire`** - Cooking at campfires or other external heat sources
- **`campsite`** - Cooking at campsites or other external heat sources
- **`cookjob`** - Job-specific cooking locations (requires `requiredjob` to be set)
- **`all`** - Recipe can be cooked at any location
- **Mixed (array)** - Recipe can be cooked at multiple specific locations (e.g., `{'stove', 'campfire'}`)

## Configuration

### Setting Recipe Cooking Types

In `shared/config.lua`, each recipe now has a `cookingtype` field:

```lua
{
    category = 'Fish',
    cooktime = 10000,
    requiredxp = 0,
    xpreward = 1,
    requiredjob = nil,
    cookingtype = 'all', -- 'stove', 'campfire', 'campsite', 'cookjob', or 'all'
    ingredients = {
        { item = 'raw_fish', amount = 1 },
    },
    receive = 'cooked_fish',
    giveamount = 1
}
```

### Recipe Type Examples

```lua
-- Can be cooked at all locations (stoves, campfires, campsites)
{
    category = 'Meat',
    cookingtype = 'all',
    -- ... rest of config
}

-- Only cookable at NPC stoves (requires proper oven)
{
    category = 'Bread',
    cookingtype = 'stove',
    -- ... rest of config
}

-- Only cookable at campfires
{
    category = 'Survival',
    cookingtype = 'campfire',
    -- ... rest of config
}

-- Only cookable at campsites
{
    category = 'Campsite Meals',
    cookingtype = 'campsite',
    -- ... rest of config
}

-- Only cookable at job-specific locations (e.g., saloon kitchen)
{
    category = 'Professional Cooking',
    cookingtype = 'cookjob',
    requiredjob = 'cook', -- Must have this job
    -- ... rest of config
}

-- Can be cooked at stoves OR campfires (but not campsites or job locations)
{
    category = 'Versatile',
    cookingtype = {'stove', 'campfire'}, -- Array of multiple types
    -- ... rest of config
}

-- Can be cooked at regular stoves OR job-specific kitchens
{
    category = 'Semi-Professional',
    cookingtype = {'stove', 'cookjob'},
    requiredjob = 'cook', -- Still requires job for cookjob locations
    -- ... rest of config
}
```

## Usage

### Opening Cooking Menu

#### For NPC Stoves
The built-in NPC interactions automatically use the `stove` type:
```lua
-- NPCs and stove props automatically trigger with 'stove' type
-- No changes needed to existing functionality
```

#### For Campfires or Campsites (External Scripts)
Use the export with the appropriate cooking type parameter:
```lua
-- Open campfire cooking menu
exports['rex-cooking']:OpenCookingMenu('campfire')

-- Open campsite cooking menu
exports['rex-cooking']:OpenCookingMenu('campsite')

-- Open job-specific cooking menu
exports['rex-cooking']:OpenCookingMenu('cookjob')
```

### Integration Examples

#### Basic ox_target Integration
```lua
-- Add cooking to campfire props
exports.ox_target:addModel(`p_campfire01x`, {
    {
        name = 'campfire_cooking',
        icon = 'fa-solid fa-fire',
        label = 'Cook at Campfire',
        onSelect = function()
            exports['rex-cooking']:OpenCookingMenu('campfire')
        end,
        distance = 2.5
    }
})
```

#### Custom Command Integration
```lua
RegisterCommand('cook', function()
    -- Check if near campfire, then open menu
    if IsNearCampfire() then
        exports['rex-cooking']:OpenCookingMenu('campfire')
    end
end, false)
```

## Exports

### Client Exports

#### OpenCookingMenu
```lua
-- Open cooking menu with specific type
exports['rex-cooking']:OpenCookingMenu(cookingType)
```
**Parameters:**
- `cookingType` (string, optional): `'stove'`, `'campfire'`, `'campsite'`, `'cookjob'`, or nil (defaults to `'stove'`)

**Example:**
```lua
-- Open stove cooking menu
exports['rex-cooking']:OpenCookingMenu('stove')

-- Open campfire cooking menu
exports['rex-cooking']:OpenCookingMenu('campfire')

-- Open campsite cooking menu
exports['rex-cooking']:OpenCookingMenu('campsite')

-- Open job-specific cooking menu
exports['rex-cooking']:OpenCookingMenu('cookjob')
```

#### GetRecipesByCookingType
```lua
-- Get all recipes available for a specific cooking type
local recipes = exports['rex-cooking']:GetRecipesByCookingType(cookingType)
```
**Parameters:**
- `cookingType` (string): `'stove'`, `'campfire'`, `'campsite'`, `'cookjob'`, or `'all'`

**Returns:**
- Table of recipes that can be cooked with the specified type

**Example:**
```lua
-- Get all campfire recipes
local campfireRecipes = exports['rex-cooking']:GetRecipesByCookingType('campfire')

print('Available campfire recipes: ' .. #campfireRecipes)
for _, recipe in ipairs(campfireRecipes) do
    print('- ' .. recipe.receive)
end
```

## Mixed Cooking Types

You can specify multiple cooking types for a recipe by using an array instead of a single string. This gives you fine-grained control over where a recipe can be cooked.

### Examples

```lua
-- Cook at stoves OR campfires only
{
    category = 'Meat',
    cookingtype = {'stove', 'campfire'},
    ingredients = { { item = 'raw_meat', amount = 1 } },
    receive = 'cooked_steak',
    giveamount = 1
}

-- Cook at all outdoor locations (campfire + campsite) but not indoor stoves
{
    category = 'Trail Food',
    cookingtype = {'campfire', 'campsite'},
    ingredients = { { item = 'raw_fish', amount = 1 } },
    receive = 'smoked_fish',
    giveamount = 1
}

-- Cook at regular stoves OR job kitchens (job still required for cookjob locations)
{
    category = 'Professional',
    cookingtype = {'stove', 'cookjob'},
    requiredjob = 'cook',
    ingredients = { { item = 'flour_wheat', amount = 2 } },
    receive = 'fancy_bread',
    giveamount = 1
}

-- Cook at any location EXCEPT job-specific kitchens
{
    category = 'Common',
    cookingtype = {'stove', 'campfire', 'campsite'},
    ingredients = { { item = 'raw_meat', amount = 1 } },
    receive = 'basic_meal',
    giveamount = 1
}
```

### When to Use Mixed Types

- **`{'stove', 'campfire'}`** - Simple foods that work on any heat source but not elaborate camp setups
- **`{'campfire', 'campsite'}`** - Wilderness/outdoor cooking only, no indoor kitchens
- **`{'stove', 'cookjob'}`** - Professional recipes that work in any kitchen (with job requirement)
- **`{'stove', 'campfire', 'campsite'}`** - Alternative to `'all'` when you want to exclude `'cookjob'`

### Comparison

| Type | Stove | Campfire | Campsite | Cookjob |
|------|-------|----------|----------|----------|
| `'all'` | ✓ | ✓ | ✓ | ✓ |
| `'stove'` | ✓ | ✗ | ✗ | ✗ |
| `{'stove', 'campfire'}` | ✓ | ✓ | ✗ | ✗ |
| `{'campfire', 'campsite'}` | ✗ | ✓ | ✓ | ✗ |
| `{'stove', 'cookjob'}` | ✓ | ✗ | ✗ | ✓* |

*Requires `requiredjob` to be set

## How It Works

1. **Recipe Filtering**: When a cooking menu is opened, recipes are automatically filtered based on the cooking type
2. **Menu Display**: The menu title shows which cooking type is active (e.g., "Cooking (Campfire)")
3. **Compatibility**: Recipes with `cookingtype = 'all'` appear in all cooking menus (stove, campfire, campsite)
4. **Backward Compatibility**: If `cookingtype` is not specified, it defaults to `'all'`

## Integration Guide

### For Campfire Script Developers

1. **Add the export call** when player interacts with your campfire:
   ```lua
   exports['rex-cooking']:OpenCookingMenu('campfire')
   ```

2. **Add ox_target support** to your campfire props/entities:
   ```lua
   exports.ox_target:addLocalEntity(campfireEntity, {
       {
           name = 'campfire_cooking',
           icon = 'fa-solid fa-fire',
           label = 'Cook at Campfire',
           onSelect = function()
               exports['rex-cooking']:OpenCookingMenu('campfire')
           end,
           distance = 2.5
       }
   })
   ```

3. **Query available recipes** to display what can be cooked:
   ```lua
   local recipes = exports['rex-cooking']:GetRecipesByCookingType('campfire')
   ```

### For Server Owners

1. **Configure recipes** in `shared/config.lua` with appropriate `cookingtype` values
2. **Set realistic cooking types**:
   - Simple foods (meat, fish) → `'all'`
   - Baked goods (bread, pies) → `'stove'`
   - Trail/survival foods → `'campfire'`
   - Campsite-specific meals → `'campsite'`
   - Job-restricted recipes → `'cookjob'`
3. **Test all cooking methods** to ensure proper filtering

## Example Configurations

### Survival-Focused Server
```lua
-- Most foods cookable at campfires and campsites
Config.Cooking = {
    { category = 'Meat', cookingtype = 'all', ... },
    { category = 'Fish', cookingtype = 'all', ... },
    { category = 'Bread', cookingtype = 'stove', ... }, -- Oven required
    { category = 'Trail Food', cookingtype = 'campfire', ... }, -- Campfire only
    { category = 'Campsite Meals', cookingtype = 'campsite', ... }, -- Campsite only
}
```

### Town-Focused Server
```lua
-- Most foods require proper kitchen
Config.Cooking = {
    { category = 'Meat', cookingtype = 'stove', ... },
    { category = 'Fish', cookingtype = 'stove', ... },
    { category = 'Bread', cookingtype = 'stove', ... },
    { category = 'Simple Meals', cookingtype = 'all', ... }, -- Basic cooking anywhere
}
```

## Tips

- Use `'all'` for simple recipes (cooked meat, fish) that can be prepared anywhere
- Use `'stove'` for complex recipes requiring controlled heat (baking, pastries)
- Use `'campfire'` for wilderness/survival recipes
- Use `'campsite'` for campsite-specific meals or setups
- Use `'cookjob'` for job-specific recipes (must also set `requiredjob`)
- Use arrays like `{'stove', 'campfire'}` for recipes that work at specific locations but not all
- The menu automatically shows which cooking type is active in the title
- Players will only see recipes available for their current cooking method

## Complete Integration Example

See `examples/campfire_integration.lua` for comprehensive integration examples including:
- ox_target integration
- Proximity detection
- Custom campfire placement systems
- Zone-based cooking
- Command integration
- Recipe querying

## Troubleshooting

**Recipes not appearing in menu:**
- Check that recipe has the correct `cookingtype` (`'campfire'`, `'campsite'`, `'cookjob'`, or `'all'`)
- For `'cookjob'` recipes, ensure `requiredjob` is set and player has the required job
- Verify you're calling `OpenCookingMenu()` with the correct cooking type parameter

**All recipes showing in all menus:**
- Recipes with `cookingtype = 'all'` (or no cookingtype field) will appear in all cooking menus
- This is intentional for maximum flexibility

**External script not working:**
- Ensure rex-cooking is started before your campfire script
- Add dependency in your fxmanifest.lua: `dependency 'rex-cooking'`
