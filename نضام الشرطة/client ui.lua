local ESX = nil
local PlayerData = {}

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(100)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(100)
    end

    PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
end)

-- #################################################################
-- ##                القائمة التفاعلية (Context Menu)            ##
-- #################################################################

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local closestPlayer, closestPlayerDistance = ESX.Game.GetClosestPlayer()

        if closestPlayer ~= -1 and closestPlayerDistance < Config.InteractionDistance then
            local targetPed = GetPlayerPed(closestPlayer)
            local targetCoords = GetEntityCoords(targetPed)

            -- Check if target is cuffed (you'd need to sync this state from server)
            -- For simplicity, we'll assume if the player is within interaction range, we can offer cuff/uncuff
            -- A more robust system would involve server-side tracking of cuffed players.
            
            ESX.ShowHelpNotification(Config.Messages.door_toggle) -- Reuse help notification for general interaction

            if IsControlJustReleased(0, Config.InteractionKey) then -- E key
                if IsPolice then
                    local elements = {
                        { label = 'تصفيد', value = 'cuff' },
                        { label = 'فك التصفيد', value = 'uncuff' },
                        { label = 'تفتيش', value = 'frisk' },
                        -- يمكنك إضافة المزيد من الخيارات هنا
                        -- { label = 'أخذ سلاح', value = 'take_weapon' },
                        -- { label = 'أخذ عنصر', value = 'take_item' },
                        -- { label = 'إعطاء عنصر', value = 'give_item' },
                        -- { label = 'إصدار غرامة', value = 'fine' },
                    }

                    ESX.UI.Menu.CloseAll()
                    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'police_interaction_menu', {
                        title    = 'تفاعل الشرطة مع ' .. GetPlayerName(closestPlayer),
                        align    = 'top-left',
                        elements = elements
                    }, function(data, menu)
                        if data.current.value == 'cuff' then
                            CuffPlayer(closestPlayer)
                        elseif data.current.value == 'uncuff' then
                            UncuffPlayer(closestPlayer)
                        elseif data.current.value == 'frisk' then
                            FriskPlayer(closestPlayer)
                        -- يمكنك إضافة المزيد من الـ handlers هنا
                        -- elseif data.current.value == 'take_weapon' then
                        --     -- ستحتاج إلى قائمة فرعية لاختيار السلاح
                        --     -- أو يمكنك تبسيطها لأخذ كل الأسلحة
                        --     TakeItem(closestPlayer, 'weapon', 'WEAPON_PISTOL', 1) -- مثال
                        end
                        menu.close()
                    end, function(data, menu)
                        menu.close()
                    end)
                else
                    ESX.ShowNotification(Config.Messages.not_police)
                end
            end
        else
            Citizen.Wait(500)
        end
    end
end)
