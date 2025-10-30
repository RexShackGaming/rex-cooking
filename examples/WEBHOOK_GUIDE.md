# Discord Webhook System - Complete Guide

## Overview
The rex-cooking script includes an extensive Discord webhook system that logs cooking activities, XP progression, job restrictions, and more to Discord channels.

## Features

### Event Logging
- **Cooking Started** - When a player begins cooking
- **Cooking Completed** - When a player successfully finishes cooking
- **Cooking Cancelled** - When a player cancels during cooking
- **Cooking Failed** - When a player lacks ingredients
- **XP Gained** - When a player earns cooking XP
- **XP Milestones** - When a player reaches XP milestones (50, 100, 250, 500, 1000, 2500)
- **Job Restrictions** - When a player tries to cook job-restricted recipes
- **Level Up** - Simulated level-up notifications (every 50 XP)
- **Recipe Unlocks** - When a player gains enough XP to unlock new recipes

### Admin Notifications
- **High XP Gains** - Alert when players gain unusually high XP
- **Suspicious Activity** - Detect potential exploits or cheating
- Separate webhook URL for admin-only notifications

### Advanced Features
- **Rate Limiting** - Prevent webhook spam with configurable limits
- **Detailed Information** - Show ingredients, cooking types, locations, jobs, etc.
- **XP Milestone Tracking** - Track which milestones players have reached
- **Customizable Templates** - Configure colors, titles, and content for each event
- **Mixed Cooking Type Support** - Properly formats array-based cooking types

## Setup

### 1. Create Discord Webhooks

#### Main Webhook (Required)
1. Go to your Discord server
2. Navigate to **Server Settings** → **Integrations** → **Webhooks**
3. Click **New Webhook**
4. Name it (e.g., "REX Cooking Logs")
5. Select the channel for cooking logs
6. Click **Copy Webhook URL**

#### Admin Webhook (Optional)
1. Repeat the above steps
2. Create a separate webhook for admin notifications
3. Select an admin-only channel
4. Copy the admin webhook URL

### 2. Configure Webhooks

Open `shared/webhook_config.lua`:

```lua
---------------------------------
-- webhook settings
---------------------------------
WebhookConfig.Enabled = true  -- Set to true to enable webhooks
WebhookConfig.WebhookURL = 'YOUR_WEBHOOK_URL_HERE'  -- Paste your main webhook URL

---------------------------------
-- admin notifications
---------------------------------
WebhookConfig.AdminNotifications = {
    Enabled = true,  -- Enable admin notifications
    WebhookURL = 'YOUR_ADMIN_WEBHOOK_URL_HERE',  -- Paste your admin webhook URL
    NotifyOnHighXP = true,
    HighXPThreshold = 100,  -- Alert if player gains 100+ XP at once
}
```

### 3. Enable/Disable Events

Configure which events you want to log:

```lua
WebhookConfig.Events = {
    CookingStarted = true,      -- Log when cooking starts
    CookingCompleted = true,    -- Log when cooking completes
    CookingCancelled = true,    -- Log when cooking is cancelled
    CookingFailed = true,       -- Log when cooking fails
    XPGained = true,            -- Log XP gains
    XPMilestone = true,         -- Log milestone achievements
    JobRestricted = true,       -- Log job restriction violations
    LevelUpSimulated = false,   -- Log simulated level ups
    RecipeUnlock = false,       -- Log recipe unlocks
}
```

### 4. Configure Detailed Information

Choose what information to include in webhooks:

```lua
WebhookConfig.DetailedInfo = {
    ShowIngredients = true,     -- Show ingredients used
    ShowCookingType = true,     -- Show cooking type (stove, campfire, etc.)
    ShowCookingTime = true,     -- Show recipe cook time
    ShowXPReward = true,        -- Show XP gained
    ShowPlayerJob = true,       -- Show player's job
    ShowLocation = true,        -- Show player coordinates
    ShowTimestamp = true,       -- Show when event occurred
}
```

## Configuration Options

### Rate Limiting

Prevent webhook spam and avoid Discord rate limits:

```lua
WebhookConfig.RateLimit = {
    Enabled = true,             -- Enable rate limiting
    MaxPerMinute = 30,          -- Maximum 30 webhooks per minute
    CooldownTime = 2000,        -- 2 second cooldown between webhooks
}
```

**Recommendation:** Keep rate limiting enabled to avoid Discord throttling.

### XP Milestones

Customize XP milestones for special notifications:

```lua
WebhookConfig.XPMilestones = {
    50,   -- Beginner Cook
    100,  -- Amateur Cook
    250,  -- Skilled Cook
    500,  -- Expert Cook
    1000, -- Master Cook
    2500, -- Grand Master Cook
}
```

Add or remove milestones as desired. Players will only be notified once per milestone.

### Webhook Colors

Customize embed colors (decimal format):

```lua
WebhookConfig.Colors = {
    Success = 65280,    -- Green (#00FF00)
    Info = 3447003,     -- Blue (#3498DB)
    Warning = 16776960, -- Yellow (#FFFF00)
    Error = 16711680,   -- Red (#FF0000)
    XP = 9442302,       -- Purple (#9013FE)
    Job = 15158332,     -- Orange (#E74C3C)
}
```

**Color Converter:** Use https://www.spycolor.com/ to convert hex to decimal.

### Custom Templates

Customize webhook appearance:

```lua
WebhookConfig.Templates = {
    CookingCompleted = {
        title = '✅ Cooking Completed',
        color = WebhookConfig.Colors.Success,
    },
    XPMilestone = {
        title = '🎉 XP Milestone Reached',
        color = WebhookConfig.Colors.Success,
    },
    -- Add more custom templates...
}
```

### Footer & Thumbnail

Add branding to webhooks:

```lua
WebhookConfig.Footer = {
    Text = 'REX Cooking System',
    IconURL = 'https://your-server.com/logo.png'  -- Optional
}

WebhookConfig.Thumbnail = {
    Enabled = true,
    DefaultURL = 'https://your-server.com/cooking-icon.png'
}
```

## Webhook Examples

### Cooking Completed Webhook

```json
{
  "title": "✅ Cooking Completed",
  "color": 65280,
  "description": "**John Marston** successfully cooked **2x Bread**",
  "fields": [
    {
      "name": "Player",
      "value": "John Marston",
      "inline": true
    },
    {
      "name": "Citizen ID",
      "value": "ABC12345",
      "inline": true
    },
    {
      "name": "Item Received",
      "value": "2x Bread",
      "inline": true
    },
    {
      "name": "Job",
      "value": "Cook (Master)",
      "inline": true
    },
    {
      "name": "XP Gained",
      "value": "+2 XP",
      "inline": true
    },
    {
      "name": "Cooking Type",
      "value": "Stove",
      "inline": true
    },
    {
      "name": "Location",
      "value": "X: -315.41, Y: 812.05, Z: 118.98",
      "inline": false
    }
  ],
  "timestamp": "2025-10-30T15:30:00Z",
  "footer": {
    "text": "REX Cooking System"
  }
}
```

### XP Milestone Webhook

```json
{
  "title": "🎉 XP Milestone Reached",
  "color": 65280,
  "description": "🎉 **Arthur Morgan** reached **500 XP** milestone and became a **Expert Cook**!",
  "fields": [
    {
      "name": "Player",
      "value": "Arthur Morgan",
      "inline": true
    },
    {
      "name": "Milestone",
      "value": "500 XP",
      "inline": true
    },
    {
      "name": "Rank Achieved",
      "value": "Expert Cook",
      "inline": true
    }
  ]
}
```

### Admin Alert Example

```json
{
  "title": "⚠️ High XP Gain Detected",
  "color": 16776960,
  "description": "Player **John Doe** gained **150 XP** in a single cooking action",
  "fields": [
    {
      "name": "Player",
      "value": "John Doe",
      "inline": true
    },
    {
      "name": "XP Gained",
      "value": "150 XP",
      "inline": true
    },
    {
      "name": "Location",
      "value": "X: 123.45, Y: 678.90, Z: 45.67",
      "inline": false
    }
  ],
  "footer": {
    "text": "REX Cooking - Admin Alert"
  }
}
```

## Performance Optimization

### Rate Limiting Best Practices

1. **Enable Rate Limiting**: Always keep `RateLimit.Enabled = true`
2. **Adjust MaxPerMinute**: Lower for busy servers (15-20), higher for quiet servers (30-50)
3. **Cooldown Time**: Minimum 1000ms recommended

### Event Selection

For high-traffic servers, consider:
- **Disable** `CookingStarted` - Can generate lots of logs
- **Disable** `CookingCancelled` - May not be critical
- **Enable** `CookingCompleted` - Important for tracking
- **Enable** `XPMilestone` - Infrequent but important
- **Enable** `JobRestricted` - Good for monitoring

### Detailed Info Settings

For cleaner webhooks:
- **Disable** `ShowLocation` if not needed
- **Disable** `ShowCookingTime` if redundant
- Keep `ShowIngredients` for completed cooking logs

## Troubleshooting

### Webhooks Not Sending

**Check:**
1. `WebhookConfig.Enabled = true` in `webhook_config.lua`
2. Webhook URL is correct and starts with `https://discord.com/api/webhooks/`
3. Check server console for error messages
4. Verify webhook hasn't been deleted in Discord
5. Check if rate limit is too strict

### Discord Returns Error 429

**Solution:** You're being rate limited by Discord
- Reduce `MaxPerMinute` value
- Increase `CooldownTime`
- Disable high-frequency events

### Webhooks Missing Information

**Check:**
1. `DetailedInfo` settings are enabled
2. Player data is available (RSG Core loaded)
3. Recipe data includes required fields

### Admin Notifications Not Working

**Check:**
1. `AdminNotifications.Enabled = true`
2. `AdminNotifications.WebhookURL` is set
3. `NotifyOnHighXP` is enabled
4. XP threshold is appropriate

## Advanced Usage

### Custom Webhook Function

You can create custom webhook notifications:

```lua
-- In server-side code
if SendAdminNotification then
    SendAdminNotification(
        'Custom Alert',
        'Custom description here',
        {
            {name = 'Field 1', value = 'Value 1', inline = true},
            {name = 'Field 2', value = 'Value 2', inline = true},
        },
        WebhookConfig.Colors.Warning
    )
end
```

### Checking Webhook Functions

Webhook functions are globally available after `server/webhooks.lua` loads:

```lua
if SendCookingCompletedWebhook then
    -- Webhook system is loaded
    SendCookingCompletedWebhook(source, recipeData)
end
```

## Security Considerations

1. **Protect Webhook URLs**: Never commit webhook URLs to public repositories
2. **Use Environment Variables**: Consider storing URLs in environment variables
3. **Admin Webhooks**: Keep admin webhooks in private channels
4. **Rate Limiting**: Always enable to prevent abuse
5. **Validation**: Webhooks validate player data before sending

## Testing

### Test Webhook Setup

1. Set `WebhookConfig.Enabled = true`
2. Add your webhook URL
3. Enable all events temporarily
4. Restart the script
5. Cook an item in-game
6. Check Discord for webhook messages

### Quick Test Command

Add this to test webhooks:

```lua
RegisterCommand('testcookingwebhook', function(source)
    if SendCookingCompletedWebhook then
        local testData = {
            receive = 'bread_sour',
            giveamount = 2,
            xpreward = 5,
            cookingtype = 'stove',
            ingredients = {
                {item = 'flour_wheat', amount = 2}
            }
        }
        SendCookingCompletedWebhook(source, testData)
        print('^2Test webhook sent^7')
    end
end, true)  -- Admin only
```

## FAQ

**Q: Do webhooks affect server performance?**
A: Minimal impact. Webhooks are asynchronous and rate-limited.

**Q: Can I use multiple webhook URLs?**
A: Yes! Main webhook for general logs, admin webhook for alerts.

**Q: What if my webhook URL leaks?**
A: Delete the webhook in Discord immediately and create a new one.

**Q: Can I disable timestamps?**
A: Yes, set `DetailedInfo.ShowTimestamp = false`

**Q: How do I convert hex colors to decimal?**
A: Use online converter or: `parseInt('0x' + hexColor.replace('#', ''))`

**Q: Can I send webhooks to multiple channels?**
A: Not directly. Create a webhook per channel or use Discord's native notification routing.

## Support

For issues or questions:
1. Check this documentation
2. Verify configuration settings
3. Check server console for errors
4. Test with minimal configuration
5. Report bugs with configuration and error logs

## Credits

REX Cooking Discord Webhook System
- Extensive event logging
- Rate limiting and performance optimization
- Admin notifications and monitoring
- Fully configurable and customizable
