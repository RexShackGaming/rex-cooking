local RSGCore = exports['rsg-core']:GetCoreObject()

-----------------------------------------------------------------------
-- version checker
-----------------------------------------------------------------------
local function versionCheckPrint(_type, log)
    local color = _type == 'success' and '^2' or '^1'
    print(('^5['..GetCurrentResourceName()..']%s %s^7'):format(color, log))
end

local function CheckVersion()
    PerformHttpRequest('https://raw.githubusercontent.com/RexShackGaming/rex-versioncheckers/main/'..GetCurrentResourceName()..'/version.txt', function(err, text, headers)
        local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
        
        -- Handle HTTP errors
        if err ~= 200 then
            versionCheckPrint('error', 'Version check failed with HTTP error: ' .. tostring(err))
            return
        end
        
        -- Handle empty response
        if not text or text == '' then
            versionCheckPrint('error', 'Currently unable to run a version check - empty response.')
            return
        end
        
        -- Clean the version text (remove whitespace)
        text = text:gsub('%s+', '')
        currentVersion = currentVersion and currentVersion:gsub('%s+', '') or 'unknown'
        
        -- Current version matched
        if text == currentVersion then 
            versionCheckPrint('success', 'Version check passed - running latest version ' .. currentVersion)
            return
        end
        
        -- Current version did not match
        versionCheckPrint('error', ('You are currently running version %s, please update to version %s'):format(currentVersion, text))
    end, 'GET', '', { ['User-Agent'] = GetCurrentResourceName() .. '/1.0' }, { timeout = 10000 })
end

--------------------------------------------------------------------------------------------------
-- start version check
--------------------------------------------------------------------------------------------------
CheckVersion()
