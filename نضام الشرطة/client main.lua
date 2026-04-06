local ESX = nil
local PlayerData = {}
local IsPolice = false
local CurrentCuffedPlayer = nil -- لتتبع اللاعب المصفد حالياً (للتفاعل معه)

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end

    PlayerData = ESX.GetPlayerData()
    CheckPoliceStatus()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    CheckPoliceStatus()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
    CheckPoliceStatus()
end)

function CheckPoliceStatus()
    IsPolice = false
    for k, v in pairs(Config.PoliceJobs) do
        if PlayerData.job.name == v then
            IsPolice = true
            break
        end
    end
end

-- #################################################################
-- ##               ميزات الأبواب (Door Features)                ##
-- #################################################################

local doorStates = {} -- لتخزين حالة كل باب (مغلق/مفتوح)

-- مزامنة حالة الأبواب عند الاتصال أو تغيير الحالة
RegisterNetEvent('esx_advancedpolice:syncDoorState')
AddEventHandler('esx_advancedpolice:syncDoorState', function(doorIndex, state)
    if Config.DoorSettings[doorIndex] then
        doorStates[doorIndex] = state
        local door = Config.DoorSettings[doorIndex]
        local doorModel = GetHashKey(door.model)
        
        -- البحث عن الكائن وتغيير حالته
        local obj = GetClosestObjectOfType(door.coords.x, door.coords.y, door.coords.z, 2.0, doorModel, false, false, false)
        if obj ~= 0 then
            SetEntityCoords(obj, door.coords.x, door.coords.y, door.coords.z - 100.0, false, false, false, true) -- إخفاء الباب مؤقتاً
            FreezeEntityPosition(obj, true) -- تجميد موقعه
            -- SetEntityRotation(obj, 0.0, 0.0, door.heading, 2, false) -- يمكن استخدامها لتغيير اتجاه الباب
            
            if state then -- إذا كان مغلقاً (true)
                -- لا شيء خاص، يبقى الباب في مكانه
                SetEntityCoords(obj, door.coords.x, door.coords.y, door.coords.z, false, false, false, true)
            else -- إذا كان مفتوحاً (false)
                -- يمكن تحريك الباب أو إخفائه
                -- في هذا المثال، سنقوم بإخفائه عن طريق تحريكه لأسفل
                SetEntityCoords(obj, door.coords.x, door.coords.y, door.coords.z - 1.5, false, false, false, true)
            end
        end
    end
end)

Citizen.CreateThread(function()
    for i, door in ipairs(Config.DoorSettings) do
        -- طلب الحالة الأولية من السيرفر
        TriggerServerEvent('esx_advancedpolice:requestDoorState', i)
    end

    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local foundDoor = false

        for i, door in ipairs(Config.DoorSettings) do
            local dist = #(playerCoords - door.coords)

            if dist < door.distance then
                foundDoor = true
                ESX.ShowHelpNotification(Config.Messages.door_toggle)

                if IsControlJustReleased(0, Config.InteractionKey) then -- E key
                    if IsPolice then
                        local isLocked = doorStates[i] or door.locked -- استخدام الحالة المزامنة
                        TriggerServerEvent('esx_advancedpolice:toggleDoorState', i, not isLocked)
                        ESX.ShowNotification(isLocked and Config.Messages.door_unlocked or Config.Messages.door_locked)
                    else
                        ESX.ShowNotification(Config.Messages.not_police)
                    end
                end
            end
        end

        if not foundDoor then
            Citizen.Wait(500) -- تقليل الحمل إذا لم يكن هناك باب قريب
        end
    end
end)

-- #################################################################
-- ##                الراديو (Radio Command)                     ##
-- #################################################################

RegisterCommand(Config.RadioCommand, function(source, args, rawCommand)
    if IsPolice then
        local message = table.concat(args, ' ')
        if message ~= '' then
            TriggerServerEvent('esx_advancedpolice:sendRadioMessage', message)
        else
            ESX.ShowNotification('الاستخدام: /' .. Config.RadioCommand .. ' [الرسالة]')
        end
    else
        ESX.ShowNotification(Config.Messages.not_police)
    end
end, false)

RegisterNetEvent('esx_advancedpolice:receiveRadioMessage')
AddEventHandler('esx_advancedpolice:receiveRadioMessage', function(senderName, message)
    if IsPolice then
        ESX.ShowNotification(string.format(Config.Messages.radio_received, senderName, message))
    end
end)

-- #################################################################
-- ##                تنبيهات 911 (911 Alerts)                    ##
-- #################################################################

RegisterNetEvent('esx_advancedpolice:send911Alert')
AddEventHandler('esx_advancedpolice:send911Alert', function(reportId, senderName, message, coords)
    if IsPolice and Config.Alerts.Enabled then
        ESX.ShowNotification(string.format(Config.Messages.alert_911, message, senderName))

        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, Config.Alerts.BlipSprite)
        SetBlipColour(blip, Config.Alerts.BlipColor)
        SetBlipScale(blip, 0.8)
        SetBlipAsShortRange(blip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(string.format("تنبيه 911 من %s", senderName))
        EndTextCommandSetBlipName(blip)

        Citizen.CreateThread(function()
            Citizen.Wait(Config.Alerts.BlipTime)
            RemoveBlip(blip)
        end)
    end
end)

-- #################################################################
-- ##                تصفيد وتفتيش (Cuffing & Frisking)           ##
-- #################################################################

-- هذه الوظائف سيتم استدعاؤها من client/ui.lua

function CuffPlayer(targetId)
    if IsPolice then
        if ESX.GetPlayerData().inventory[Config.CuffItem] and ESX.GetPlayerData().inventory[Config.CuffItem].count > 0 then
            TriggerServerEvent('esx_advancedpolice:cuffPlayer', GetPlayerServerId(targetId))
        else
            ESX.ShowNotification(Config.Messages.no_handcuffs)
        end
    else
        ESX.ShowNotification(Config.Messages.not_police)
    end
end

function UncuffPlayer(targetId)
    if IsPolice then
        TriggerServerEvent('esx_advancedpolice:uncuffPlayer', GetPlayerServerId(targetId))
    else
        ESX.ShowNotification(Config.Messages.not_police)
    end
end

function FriskPlayer(targetId)
    if IsPolice then
        TriggerServerEvent('esx_advancedpolice:friskPlayer', GetPlayerServerId(targetId))
    else
        ESX.ShowNotification(Config.Messages.not_police)
    end
end

RegisterNetEvent('esx_advancedpolice:client:cuffPlayer')
AddEventHandler('esx_advancedpolice:client:cuffPlayer', function()
    local playerPed = PlayerPedId()
    RequestAnimDict("mp_arresting")
    while not HasAnimDictLoaded("mp_arresting") do
        Citizen.Wait(0)
    end
    TaskPlayAnim(playerPed, "mp_arresting", "a_f_y_cuff_to_cuff", 8.0, -8.0, Config.CuffTime, 49, 0, false, false, false)
    Citizen.Wait(Config.CuffTime)
    ClearPedTasks(playerPed)
    
    -- تصفيد اللاعب (منعه من الحركة)
    FreezeEntityPosition(playerPed, true)
    SetEnableHandcuffs(playerPed, true) -- لإظهار الكلبشات على اللاعب
    DisableControlAction(0, 73, true) -- disable F (exit vehicle)
    DisableControlAction(0, 22, true) -- disable SPACE (jump)
    DisableControlAction(0, 24, true) -- disable ATTACK
    DisableControlAction(0, 257, true) -- disable ATTACK
    DisableControlAction(0, 25, true) -- disable AIM
    DisableControlAction(0, 263, true) -- disable melee
    DisableControlAction(0, 47, true) -- disable weapon
    DisableControlAction(0, 58, true) -- disable weapon
    DisableControlAction(0, 140, true) -- disable melee
    DisableControlAction(0, 141, true) -- disable melee
    DisableControlAction(0, 142, true) -- disable melee
    DisableControlAction(0, 143, true) -- disable melee
    
    ESX.ShowNotification(Config.Messages.cuffed)
end)

RegisterNetEvent('esx_advancedpolice:client:uncuffPlayer')
AddEventHandler('esx_advancedpolice:client:uncuffPlayer', function()
    local playerPed = PlayerPedId()
    ClearPedTasksImmediately(playerPed)
    FreezeEntityPosition(playerPed, false)
    SetEnableHandcuffs(playerPed, false)
    
    ESX.ShowNotification(Config.Messages.uncuffed)
end)

RegisterNetEvent('esx_advancedpolice:client:friskResult')
AddEventHandler('esx_advancedpolice:client:friskResult', function(targetName, foundItems)
    local itemsString = ''
    if #foundItems > 0 then
        for i, item in ipairs(foundItems) do
            itemsString = itemsString .. item.label .. ' x' .. item.count
            if i < #foundItems then
                itemsString = itemsString .. ', '
            end
        end
        ESX.ShowNotification(string.format(Config.Messages.frisk_success, targetName, itemsString))
    else
        ESX.ShowNotification(string.format(Config.Messages.frisk_empty, targetName))
    end
end)

-- #################################################################
-- ##                مزامنة العناصر (Item Sync)                 ##
-- #################################################################

function TakeItem(targetId, itemType, itemName, count)
    if IsPolice then
        TriggerServerEvent('esx_advancedpolice:takeItem', GetPlayerServerId(targetId), itemType, itemName, count)
    else
        ESX.ShowNotification(Config.Messages.not_police)
    end
end

function GiveItem(targetId, itemType, itemName, count)
    if IsPolice then
        TriggerServerEvent('esx_advancedpolice:giveItem', GetPlayerServerId(targetId), itemType, itemName, count)
    else
        ESX.ShowNotification(Config.Messages.not_police)
    end
end

RegisterNetEvent('esx_advancedpolice:itemTakenNotification')
AddEventHandler('esx_advancedpolice:itemTakenNotification', function(itemName, targetName)
    ESX.ShowNotification(string.format(Config.Messages.item_taken, itemName, targetName))
end)

RegisterNetEvent('esx_advancedpolice:itemGivenNotification')
AddEventHandler('esx_advancedpolice:itemGivenNotification', function(itemName, targetName)
    ESX.ShowNotification(string.format(Config.Messages.item_given, itemName, targetName))
end)
