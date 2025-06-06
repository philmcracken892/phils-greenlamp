local lureObjects = {}
local activeLights = {}
local LURE_MODEL = "p_lantern_brass_001"
local LURE_DURATION = 60000 -- 60 seconds

-- Color presets
local LIGHT_COLORS = {
    green = {r = 0, g = 255, b = 0, name = "Green"},
    red = {r = 255, g = 0, b = 0, name = "Red"},
    blue = {r = 0, g = 0, b = 255, name = "Blue"},
    white = {r = 255, g = 255, b = 255, name = "White"},
    yellow = {r = 255, g = 255, b = 0, name = "Yellow"},
    purple = {r = 255, g = 0, b = 255, name = "Purple"},
    orange = {r = 255, g = 165, b = 0, name = "Orange"},
    cyan = {r = 0, g = 255, b = 255, name = "Cyan"},
    rainbow = {r = 255, g = 0, b = 0, name = "Rainbow"} -- Starting color for rainbow
}

local DEFAULT_COLOR = "green"

RegisterNetEvent('rsg-scentlure:client:UseLure', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local forward = GetEntityForwardVector(playerPed)
    local dropCoords = coords + forward * 1.0
    dropCoords = vector3(dropCoords.x, dropCoords.y, coords.z - 1.0)
    
    TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
    Wait(2500)
    ClearPedTasks(playerPed)
    
    RequestModel(LURE_MODEL)
    while not HasModelLoaded(LURE_MODEL) do Wait(10) end
    
    local obj = CreateObject(GetHashKey(LURE_MODEL), dropCoords.x, dropCoords.y, dropCoords.z, true, true, false)
    PlaceObjectOnGroundProperly(obj)
    FreezeEntityPosition(obj, true)
    SetModelAsNoLongerNeeded(LURE_MODEL)
    
    local netId = ObjToNet(obj)
    local objCoords = GetEntityCoords(obj)
    
    table.insert(lureObjects, obj)
    
    
    table.insert(activeLights, {
        object = obj,
        coords = objCoords,
        netId = netId,
        startTime = GetGameTimer(),
        color = DEFAULT_COLOR
    })
    
    
    Wait(100)
    TriggerServerEvent('rsg-scentlure:server:RegisterLure', netId, objCoords)
    
    
    local targetOptions = {
        {
            label = 'Pick Up Lamp',
            icon = 'fas fa-hand-paper',
            onSelect = function()
                TaskStartScenarioInPlace(playerPed, GetHashKey('WORLD_HUMAN_CROUCH_INSPECT'), -1, true, false, false, false)
                Wait(2500)
                ClearPedTasks(playerPed)
                
                
                for i = #lureObjects, 1, -1 do
                    if lureObjects[i] == obj then
                        table.remove(lureObjects, i)
                        break
                    end
                end
                
                
                if DoesEntityExist(obj) then 
                    DeleteObject(obj) 
                end
                
                
                TriggerServerEvent('rsg-scentlure:server:ReturnLure', netId)
            end,
            distance = 2.5
        },
        {
            label = 'Change Color',
            icon = 'fas fa-palette',
            onSelect = function()
                
                local colorOptions = {}
                for colorKey, colorData in pairs(LIGHT_COLORS) do
                    table.insert(colorOptions, {
                        title = colorData.name,
                        description = "Change lamp to " .. colorData.name:lower() .. " color",
                        onSelect = function()
                            TriggerEvent('rsg-scentlure:client:ChangeColor', {
                                netId = netId,
                                color = colorKey
                            })
                        end
                    })
                end
                
                lib.registerContext({
                    id = 'lure_color_menu',
                    title = 'Select Lamp Color',
                    options = colorOptions
                })
                
                lib.showContext('lure_color_menu')
            end,
            distance = 2.5
        }
    }
    
    exports.ox_target:addLocalEntity(obj, targetOptions)
end)

RegisterNetEvent('rsg-scentlure:client:ChangeColor', function(data)
    local netId = data.netId
    local newColor = data.color
    
   
    for _, light in ipairs(activeLights) do
        if light.netId == netId then
            light.color = newColor
            break
        end
    end
    
    
    TriggerServerEvent('rsg-scentlure:server:ChangeColor', netId, newColor)
    
    
    lib.notify({
        title = 'Lamp Color Changed',
        description = 'Lamp color changed to ' .. LIGHT_COLORS[newColor].name,
        type = 'success'
    })
end)

RegisterNetEvent('rsg-scentlure:client:AddLureLight', function(netId, coords, color)
    color = color or DEFAULT_COLOR
    
    
    for _, light in ipairs(activeLights) do
        if light.netId == netId then
            print("^3[LIGHT WARNING]^7 Light already exists for netId " .. tostring(netId))
            return
        end
    end
    
    
    local obj = nil
    if NetworkDoesEntityExistWithNetworkId(netId) then
        obj = NetworkGetEntityFromNetworkId(netId)
    end
    
   
    if not obj or not DoesEntityExist(obj) then
       
        
        RequestModel(LURE_MODEL)
        while not HasModelLoaded(LURE_MODEL) do Wait(10) end
        
        obj = CreateObject(GetHashKey(LURE_MODEL), coords.x, coords.y, coords.z, false, true, false)
        PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
        SetModelAsNoLongerNeeded(LURE_MODEL)
        
        
        table.insert(lureObjects, obj)
    end
    
    local lightCoords = GetEntityCoords(obj)
    
    table.insert(activeLights, {
        object = obj,
        coords = lightCoords,
        netId = netId,
        startTime = GetGameTimer(),
        isLocallyCreated = not NetworkDoesEntityExistWithNetworkId(netId),
        color = color
    })
    
    
end)

RegisterNetEvent('rsg-scentlure:client:UpdateLureColor', function(netId, newColor)
    for _, light in ipairs(activeLights) do
        if light.netId == netId then
            light.color = newColor
           
            break
        end
    end
end)

RegisterNetEvent('rsg-scentlure:client:RemoveLureLight', function(netId)
    local removed = false
    for i = #activeLights, 1, -1 do
        local light = activeLights[i]
        if light.netId == netId then
           
            if light.isLocallyCreated and light.object and DoesEntityExist(light.object) then
                DeleteObject(light.object)
                
                
                for j = #lureObjects, 1, -1 do
                    if lureObjects[j] == light.object then
                        table.remove(lureObjects, j)
                        break
                    end
                end
            end
            
            table.remove(activeLights, i)
            removed = true
           
            break
        end
    end
    
    if not removed then
        
    end
end)

-- Light render loop
CreateThread(function()
    while true do
        Wait(0)
        for _, light in ipairs(activeLights) do
            local color
            if light.color == "rainbow" then
                
                local time = GetGameTimer() / 1000.0 
                local hue = (time * 50) % 360 
                color = HSVtoRGB(hue, 1.0, 1.0)
            else
                color = LIGHT_COLORS[light.color] or LIGHT_COLORS[DEFAULT_COLOR]
            end
            DrawLightWithRange(light.coords.x, light.coords.y, light.coords.z + 0.5, color.r, color.g, color.b, 5.0, 1.5)
        end
    end
end)


function HSVtoRGB(h, s, v)
    local r, g, b
    local i = math.floor(h / 60) % 6
    local f = (h / 60) - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)

    if i == 0 then
        r, g, b = v, t, p
    elseif i == 1 then
        r, g, b = q, v, p
    elseif i == 2 then
        r, g, b = p, v, t
    elseif i == 3 then
        r, g, b = p, q, v
    elseif i == 4 then
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end

    return {r = math.floor(r * 255), g = math.floor(g * 255), b = math.floor(b * 255)}
end


CreateThread(function()
    while true do
        Wait(1000)
        local now = GetGameTimer()
        for i = #activeLights, 1, -1 do
            if now - activeLights[i].startTime >= LURE_DURATION then
                local expiredLight = activeLights[i]
                
                
                if expiredLight.isLocallyCreated and expiredLight.object and DoesEntityExist(expiredLight.object) then
                    DeleteObject(expiredLight.object)
                    
                   
                    for j = #lureObjects, 1, -1 do
                        if lureObjects[j] == expiredLight.object then
                            table.remove(lureObjects, j)
                            break
                        end
                    end
                end
                
                table.remove(activeLights, i)
               
                
                
                TriggerServerEvent('rsg-scentlure:server:LureTimeout', expiredLight.netId)
            end
        end
    end
end)