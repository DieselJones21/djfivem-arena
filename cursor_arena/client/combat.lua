local lastHealth = 200
local lastHitAt = 0

local function playHit(kind, damage)
    if not Config.HitMarkers.enabled then return end
    SendNUIMessage({
        action = 'hitmarker',
        kind = kind, -- hit | kill | headshot
        damage = Config.HitMarkers.damage and damage or nil,
    })
    if not Arena.Client.muteSounds then
        PlaySoundFrontend(-1, kind == 'headshot' and 'CHECKPOINT_PERFECT' or 'WEAPON_ATTACHMENT_UNEQUIP', 'HUD_AMMO_SHOP_SOUNDSET', true)
    end
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if not Arena.Client.inArena then return end

    local victim = args[1]
    local attacker = args[2]
    local ped = PlayerPedId()
    if attacker ~= ped then return end
    if not IsEntityAPed(victim) then return end

    local fatal = args[6] == 1
    local weapon = args[7] or args[5]
    local boneHit = args[10] or args[9]
    local headshot = boneHit == 31086 or boneHit == 39317

    local dmg = 0
    if IsEntityAPed(victim) then
        -- approximate from remaining health when we can read it
        local hp = GetEntityHealth(victim)
        if hp and lastHealth then
            dmg = math.max(0, 200 - hp)
        end
    end

    local now = GetGameTimer()
    if now - lastHitAt < 40 then return end
    lastHitAt = now

    if fatal then
        playHit(headshot and 'headshot' or 'kill', dmg > 0 and dmg or 100)
    else
        playHit(headshot and 'headshot' or 'hit', dmg > 0 and dmg or 25)
    end
end)

RegisterNetEvent('cursor_arena:client:killstreak', function(streak)
    if Arena.Client.muteStreaks then return end
    SendNUIMessage({
        action = 'killstreak',
        style = Config.KillstreakStyle,
        label = streak.label,
        kills = streak.kills,
        volume = Config.KillstreakVolume,
    })
    if KillstreakReward then KillstreakReward(streak) end
    if not Arena.Client.muteSounds then
        PlaySoundFrontend(-1, 'MEDAL_UP', 'HUD_MINI_GAME_SOUNDSET', true)
    end
end)

RegisterNetEvent('cursor_arena:client:killstreakCall', function(data)
    if Arena.Client.muteStreaks then return end
    SendNUIMessage({ action = 'killstreakCall', data = data })
end)

RegisterNetEvent('cursor_arena:client:killReward', function(data)
    if GiveKillReward then
        GiveKillReward({ health = data.health, armor = data.armor })
    end
end)

RegisterNetEvent('cursor_arena:client:sound', function(kind)
    if Arena.Client.muteSounds then return end
    SendNUIMessage({ action = 'sound', kind = kind })
    if kind == 'bell' then
        PlaySoundFrontend(-1, 'TIMER_STOP', 'HUD_MINI_GAME_SOUNDSET', true)
    elseif kind == 'round_start' then
        PlaySoundFrontend(-1, '5_Second_Timer', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', true)
    elseif kind == 'round_end' then
        PlaySoundFrontend(-1, 'CHECKPOINT_NORMAL', 'HUD_MINI_GAME_SOUNDSET', true)
    elseif kind == 'game_over' then
        PlaySoundFrontend(-1, 'CHECKPOINT_PERFECT', 'HUD_MINI_GAME_SOUNDSET', true)
    end
end)

CreateThread(function()
    while true do
        if Arena.Client.inArena then
            lastHealth = GetEntityHealth(PlayerPedId())
            Wait(200)
        else
            Wait(1000)
        end
    end
end)
