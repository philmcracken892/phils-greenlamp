local RSGCore = exports['rsg-core']:GetCoreObject()
local playerLures = {}
local lureColors = {} 

RSGCore.Functions.CreateUseableItem('greenlamp', function(source)
    local Player = RSGCore.Functions.GetPlayer(source)
    if Player then
        local placed = playerLures[source] or {}
        if #placed >= 2 then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Lure Limit Reached',
                description = 'You already have 2 active lamps.',
                type = 'error'
            })
            return
        end
        if Player.Functions.RemoveItem('greenlamp', 1) then
            TriggerClientEvent('inventory:client:ItemBox', source, RSGCore.Shared.Items['greenlamp'], "remove")
            TriggerClientEvent('rsg-scentlure:client:UseLure', source)
        else
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'No Scent Lure',
                description = "You don't have a lamp.",
                type = 'error'
            })
        end
    end
end)

RegisterNetEvent('rsg-scentlure:server:ReturnLure', function(netId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
   
    Player.Functions.AddItem('greenlamp', 1)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items['greenlamp'], "add")
    
   
    if playerLures[src] then
        for i, nid in ipairs(playerLures[src]) do
            if nid == netId then
                table.remove(playerLures[src], i)
                break
            end
        end
    end
    
    
    lureColors[netId] = nil
    
    
    TriggerClientEvent('rsg-scentlure:client:RemoveLureLight', -1, netId)
    
   
end)

RegisterNetEvent('rsg-scentlure:server:RegisterLure', function(netId, coords)
    local src = source
    playerLures[src] = playerLures[src] or {}
    table.insert(playerLures[src], netId)
    
   
    lureColors[netId] = "green"
    
    
    TriggerClientEvent('rsg-scentlure:client:AddLureLight', -1, netId, coords, "green")
    
   
end)

RegisterNetEvent('rsg-scentlure:server:ChangeColor', function(netId, newColor)
    local src = source
    
    
    lureColors[netId] = newColor
    
   
    TriggerClientEvent('rsg-scentlure:client:UpdateLureColor', -1, netId, newColor)
    
   
end)


RegisterNetEvent('rsg-scentlure:server:LureTimeout', function(netId)
    local src = source
    
    
    if playerLures[src] then
        for i, nid in ipairs(playerLures[src]) do
            if nid == netId then
                table.remove(playerLures[src], i)
                break
            end
        end
    end
    
    
    lureColors[netId] = nil
    
    
    TriggerClientEvent('rsg-scentlure:client:RemoveLureLight', -1, netId)
    
   
end)


AddEventHandler('playerDropped', function()
    local src = source
    if playerLures[src] then
       
        for _, netId in ipairs(playerLures[src]) do
            
            lureColors[netId] = nil
            TriggerClientEvent('rsg-scentlure:client:RemoveLureLight', -1, netId)
        end
        playerLures[src] = nil
    end
end)