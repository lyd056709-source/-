local ESX = nil
local PlayersCuffed = {} -- { [source] = true/false } لتتبع اللاعبين المصفدين

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end
end)

-- #################################################################
-- ##               ميزات الأبواب (Door Features)                ##
-- #################################################################

local doorStates = {} -- [doorIndex] = true/false (true = locked, false = unlocked)

-- تهيئة حالة الأبواب من الإعدادات
for i, door in ipairs(Config.DoorSettings) do
    doorStates[i] = door.locked
end

RegisterNetEvent('esx_advancedpolice:requestDoorState')
AddEventHandler('esx_advancedpolice:requestDoorState', function(doorIndex)
    local _source = source
    if Config.DoorSettings[doorIndex] then
        TriggerClientEvent('esx_advancedpolice:syncDoorState', _source, doorIndex, doorStates[doorIndex])
    end
end)

RegisterNetEvent('esx_advancedpolice:toggleDoorState')
AddEventHandler('esx_advancedpolice:toggleDoorState', function(doorIndex, newState)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer and Config.DoorSettings[doorIndex] then
        local isAuthorized = false
        for k, v in pairs(Config.DoorSettings[doorIndex].authorizedJobs) do
            if xPlayer.job.name == v then
                isAuthorized = true
                break
            end
        end

        if isAuthorized then
            doorStates[doorIndex] = newState
            -- مزامنة الحالة الجديدة لجميع اللاعبين
            TriggerClientEvent('esx_advancedpolice:syncDoorState', -1, doorIndex, newState)
        else
            ESX.ShowNotification(_source, Config.Messages.not_police)
        end
    end
end)

-- #################################################################
-- ##                الراديو (Radio Command)                     ##
-- #################################################################

RegisterNetEvent('esx_advancedpolice:sendRadioMessage')
AddEventHandler('esx_advancedpolice:sendRadioMessage', function(message)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        local isPolice = false
        for k, v in pairs(Config.PoliceJobs) do
            if xPlayer.job.name == v then
                isPolice = true
                break
            end
        end

        if isPolice then
            -- إرسال الرسالة لجميع ضباط الشرطة
            for k, v in pairs(ESX.GetPlayers()) do
                local targetPlayer = ESX.GetPlayerFromId(v)
                if targetPlayer and targetPlayer.job.name == 'police' then -- يمكنك تعميمها على Config.PoliceJobs
                    TriggerClientEvent('esx_advancedpolice:receiveRadioMessage', v, xPlayer.name, message)
                end
            end
            ESX.ShowNotification(_source, string.format(Config.Messages.radio_sent, Config.RadioChannel, message))
        else
            ESX.ShowNotification(_source, Config.Messages.not_police)
        end
    end
end)

-- #################################################################
-- ##                تنبيهات 911 (911 Alerts)                    ##
-- #################################################################

-- هذا الحدث يمكن استدعاؤه من سكربت آخر (مثل سكربت 911 مخصص)
-- مثال: TriggerServerEvent('esx_advancedpolice:trigger911Alert', 'سرقة متجر', GetEntityCoords(PlayerPedId()))
RegisterNetEvent('esx_advancedpolice:trigger911Alert')
AddEventHandler('esx_advancedpolice:trigger911Alert', function(message, coords)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)

    if xPlayer then
        local senderName = xPlayer.name
        -- إرسال التنبيه لجميع ضباط الشرطة
        for k, v in pairs(ESX.GetPlayers()) do
            local targetPlayer = ESX.GetPlayerFromId(v)
            if targetPlayer and targetPlayer.job.name == 'police' then
                TriggerClientEvent('esx_advancedpolice:send911Alert', v, _source, senderName, message, coords)
            end
        end
    end
end)

-- #################################################################
-- ##                تصفيد وتفتيش (Cuffing & Frisking)           ##
-- #################################################################

RegisterNetEvent('esx_advancedpolice:cuffPlayer')
AddEventHandler('esx_advancedpolice:cuffPlayer', function(targetId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer and targetPlayer then
        if xPlayer.getInventoryItem(Config.CuffItem).count > 0 then
            xPlayer.removeInventoryItem(Config.CuffItem, 1)
            PlayersCuffed[targetId] = true
            TriggerClientEvent('esx_advancedpolice:client:cuffPlayer', targetId)
        else
            ESX.ShowNotification(_source, Config.Messages.no_handcuffs)
        end
    else
        ESX.ShowNotification(_source, Config.Messages.player_not_found)
    end
end)

RegisterNetEvent('esx_advancedpolice:uncuffPlayer')
AddEventHandler('esx_advancedpolice:uncuffPlayer', function(targetId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer and targetPlayer then
        if PlayersCuffed[targetId] then
            PlayersCuffed[targetId] = false
            TriggerClientEvent('esx_advancedpolice:client:uncuffPlayer', targetId)
        else
            ESX.ShowNotification(_source, Config.Messages.player_not_cuffed)
        end
    else
        ESX.ShowNotification(_source, Config.Messages.player_not_found)
    end
end)

RegisterNetEvent('esx_advancedpolice:friskPlayer')
AddEventHandler('esx_advancedpolice:friskPlayer', function(targetId)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if _source == targetId then
        ESX.ShowNotification(_source, Config.Messages.frisk_self)
        return
    end

    if xPlayer and targetPlayer then
        local foundItems = {}
        local targetInventory = targetPlayer.getInventory()
        local targetWeapons = targetPlayer.getWeapons()

        -- تفتيش المخزون
        for i=1, #targetInventory, 1 do
            local item = targetInventory[i]
            if item.count > 0 then
                for k, v in pairs(Config.ContrabandItems) do
                    if item.name == v then
                        table.insert(foundItems, { label = item.label, name = item.name, count = item.count, type = 'item' })
                        break
                    end
                end
            end
        end

        -- تفتيش الأسلحة
        for i=1, #targetWeapons, 1 do
            local weapon = targetWeapons[i]
            if weapon.name ~= 'WEAPON_UNARMED' then -- تجاهل الأيدي الفارغة
                for k, v in pairs(Config.ContrabandItems) do
                    if weapon.name == v then
                        table.insert(foundItems, { label = ESX.GetWeaponLabel(weapon.name), name = weapon.name, count = weapon.ammo, type = 'weapon' })
                        break
                    end
                end
            end
        end

        TriggerClientEvent('esx_advancedpolice:client:friskResult', _source, targetPlayer.name, foundItems)
    else
        ESX.ShowNotification(_source, Config.Messages.player_not_found)
    end
end)

-- #################################################################
-- ##                مزامنة العناصر (Item Sync)                 ##
-- #################################################################

RegisterNetEvent('esx_advancedpolice:takeItem')
AddEventHandler('esx_advancedpolice:takeItem', function(targetId, itemType, itemName, count)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer and targetPlayer then
        if itemType == 'item' then
            if targetPlayer.getInventoryItem(itemName).count >= count then
                targetPlayer.removeInventoryItem(itemName, count)
                xPlayer.addInventoryItem(itemName, count)
                TriggerClientEvent('esx_advancedpolice:itemTakenNotification', _source, ESX.GetItemLabel(itemName), targetPlayer.name)
            else
                ESX.ShowNotification(_source, 'اللاعب لا يمتلك هذا العدد من العنصر.')
            end
        elseif itemType == 'weapon' then
            if targetPlayer.hasWeapon(itemName) then
                targetPlayer.removeWeapon(itemName)
                xPlayer.addWeapon(itemName, count) -- count هنا هي الذخيرة
                TriggerClientEvent('esx_advancedpolice:itemTakenNotification', _source, ESX.GetWeaponLabel(itemName), targetPlayer.name)
            else
                ESX.ShowNotification(_source, 'اللاعب لا يمتلك هذا السلاح.')
            end
        end
    else
        ESX.ShowNotification(_source, Config.Messages.player_not_found)
    end
end)

RegisterNetEvent('esx_advancedpolice:giveItem')
AddEventHandler('esx_advancedpolice:giveItem', function(targetId, itemType, itemName, count)
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)

    if xPlayer and targetPlayer then
        if itemType == 'item' then
            if xPlayer.getInventoryItem(itemName).count >= count then
                xPlayer.removeInventoryItem(itemName, count)
                targetPlayer.addInventoryItem(itemName, count)
                TriggerClientEvent('esx_advancedpolice:itemGivenNotification', _source, ESX.GetItemLabel(itemName), targetPlayer.name)
            else
                ESX.ShowNotification(_source, 'أنت لا تمتلك هذا العدد من العنصر.')
            end
        elseif itemType == 'weapon' then
            if xPlayer.hasWeapon(itemName) then
                xPlayer.removeWeapon(itemName)
                targetPlayer.addWeapon(itemName, count) -- count هنا هي الذخيرة
                TriggerClientEvent('esx_advancedpolice:itemGivenNotification', _source, ESX.GetWeaponLabel(itemName), targetPlayer.name)
            else
                ESX.ShowNotification(_source, 'أنت لا تمتلك هذا السلاح.')
            end
        end
    else
        ESX.ShowNotification(_source, Config.Messages.player_not_found)
    end
end)

-- عند مغادرة اللاعب، تأكد من فك تصفيده
AddEventHandler('playerDropped', function()
    local _source = source
    if PlayersCuffed[_source] then
        PlayersCuffed[_source] = false
        -- لا حاجة لإرسال حدث للعميل لأنه غادر
    end
end)
