local RSGCore = exports['rsg-core']:GetCoreObject()
local spawnedPeds = {}
local spawnedBlips = {}
local lastUpdateTime = 0
local UPDATE_INTERVAL = Config.UpdateInterval or 1000 -- use config value
local activeFadeCount = 0

-- create blips for cooking locations
CreateThread(function()
    Wait(1000)
    for k, v in pairs(Config.CookingLocations) do
        if v.showblip then
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(blip, Config.BlipSprite or `blip_grub`, true)
            Citizen.InvokeNative(0x9CB1A1623062F402, blip, v.name or 'Cooking Location')
            spawnedBlips[k] = blip
        end
    end
end)

CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        if currentTime - lastUpdateTime >= UPDATE_INTERVAL then
            lastUpdateTime = currentTime
            for k,v in pairs(Config.CookingLocations) do
            local playerCoords = GetEntityCoords(cache.ped)
            local distance = #(playerCoords - v.npccoords.xyz)

                if distance < Config.DistanceSpawn and not spawnedPeds[k] then
                    local spawnedPed = NearPed(v.npcmodel, v.npccoords)
                    spawnedPeds[k] = { spawnedPed = spawnedPed }
                end
                
                if distance >= Config.DistanceSpawn and spawnedPeds[k] then
                    if Config.FadeIn and activeFadeCount < (Config.MaxConcurrentFades or 5) then
                        activeFadeCount = activeFadeCount + 1
                        CreateThread(function() -- non-blocking fade out
                            local pedToFade = spawnedPeds[k].spawnedPed
                            for i = 255, 0, -51 do
                                Wait(50)
                                if DoesEntityExist(pedToFade) then
                                    SetEntityAlpha(pedToFade, i, false)
                                end
                            end
                            if DoesEntityExist(pedToFade) then
                                DeletePed(pedToFade)
                            end
                            spawnedPeds[k] = nil
                            activeFadeCount = math.max(0, activeFadeCount - 1)
                        end)
                    else
                        if DoesEntityExist(spawnedPeds[k].spawnedPed) then
                            DeletePed(spawnedPeds[k].spawnedPed)
                        end
                        spawnedPeds[k] = nil
                    end
                end
            end
        end
        Wait(200)
	end
end)

function NearPed(npcmodel, npccoords)
    RequestModel(npcmodel)
    local timeout = GetGameTimer() + (Config.ModelTimeout or 5000)
    while not HasModelLoaded(npcmodel) do
        if GetGameTimer() > timeout then
            print("^1[ERROR] Failed to load NPC model: " .. npcmodel .. "^7")
            return nil
        end
        Wait(50)
    end
    
    local spawnedPed = CreatePed(npcmodel, npccoords.x, npccoords.y, npccoords.z - 1.0, npccoords.w, false, false, 0, 0)
    if not spawnedPed then return nil end
    
    SetEntityAlpha(spawnedPed, 0, false)
    SetRandomOutfitVariation(spawnedPed, true)
    SetEntityCanBeDamaged(spawnedPed, false)
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    SetPedCanBeTargetted(spawnedPed, false)
    SetPedFleeAttributes(spawnedPed, 0, false)
    
    if Config.FadeIn and activeFadeCount < (Config.MaxConcurrentFades or 5) then
        activeFadeCount = activeFadeCount + 1
        CreateThread(function()
            for i = 0, 255, 51 do
                if DoesEntityExist(spawnedPed) then
                    SetEntityAlpha(spawnedPed, i, false)
                end
                Wait(50)
            end
            activeFadeCount = math.max(0, activeFadeCount - 1)
        end)
    else
        SetEntityAlpha(spawnedPed, 255, false)
    end
    if Config.EnableTarget and spawnedPed then
        exports.ox_target:addLocalEntity(spawnedPed, {
            {
                name = 'npc_cooking',
                icon = 'far fa-eye',
                label = locale('cl_lang_1'),
                onSelect = function()
                    TriggerEvent('rex-cooking:client:cookingmenu', { cookingType = 'cookjob' })
                end,
                distance = 3.0
            }
        })
    end
    
    SetModelAsNoLongerNeeded(npcmodel)
    return spawnedPed
end

---------------------------------
-- cleanup
---------------------------------
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    -- cleanup peds
    for k,v in pairs(spawnedPeds) do
        if v.spawnedPed and DoesEntityExist(v.spawnedPed) then
            DeletePed(v.spawnedPed)
        end
    end
    spawnedPeds = {}
    
    -- cleanup blips
    for k, blip in pairs(spawnedBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    spawnedBlips = {}
end)
