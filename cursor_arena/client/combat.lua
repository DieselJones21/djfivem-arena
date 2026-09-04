local lastHitAt = 0
local lastHeadshotAt = 0

local HEAD_BONES = {
    [31086] = true, -- SKEL_Head
    [39317] = true, -- SKEL_Neck_1
    [12844] = true, -- IK_Head
    [65068] = true, -- SKEL_Neck_1 alt
}

local function headBones()
    local list = Config.Combat and Config.Combat.headBones
    if not list then return HEAD_BONES end
    local set = {}
    for i = 1, #list do
        set[list[i]] = true
    end
    return set
end

local HEADS = headBones()

local function isHeadBone(bone)
    bone = tonumber(bone)
    return bone and HEADS[bone] == true
end

local function pedTookHeadshot(ped)
    if not ped or ped == 0 then return false end
    local ok, bone = GetPedLastDamageBone(ped)
    if ok == true and isHeadBone(bone) then return true end
    if type(ok) == 'number' and isHeadBone(ok) then return true end
    return false
end

local function playHit(kind, damage)
    if not Config.HitMarkers.enabled then return end
    SendNUIMessage({
        action = 'hitmarker',
        kind = kind,
        damage = Config.HitMarkers.damage and damage or nil,
    })
    if not Arena.Client.muteSounds then
        PlaySoundFrontend(-1, kind == 'headshot' and 'CHECKPOINT_PERFECT' or 'WEAPON_ATTACHMENT_UNEQUIP', 'HUD_AMMO_SHOP_SOUNDSET', true)
    end
end

local function applyHeadshotKill(ped)
    if not ped or ped == 0 then return end
    if Arena.Client.frozen or Arena.Client.down then return end
    if not Arena.Client.lobby or Arena.Client.lobby.state ~= 'active' then return end
    SetPedSuffersCriticalHits(ped, true)
    SetEntityHealth(ped, 0)
end

AddEventHandler('gameEventTriggered', function(name, args)
    if name ~= 'CEventNetworkEntityDamage' then return end
    if not Arena.Client.inArena then return end

    local victim = args[1]
    local attacker = args[2]
    local ped = PlayerPedId()
    if not IsEntityAPed(victim) then return end

    local fatal = args[6] == 1
    local boneHit = args[10] or args[9] or args[11]
    local headshot = isHeadBone(boneHit) or pedTookHeadshot(victim)
    local instant = Config.Combat == nil or Config.Combat.headshotInstant ~= false

    if victim == ped and headshot and instant then
        applyHeadshotKill(ped)
    end

    if attacker ~= ped then return end

    local now = GetGameTimer()
    if now - lastHitAt < 40 then return end
    lastHitAt = now

    local dmg = 0
    local hp = GetEntityHealth(victim)
    if hp then
        dmg = math.max(0, 200 - hp)
    end

    if fatal or (headshot and instant) then
        playHit(headshot and 'headshot' or 'kill', dmg > 0 and dmg or 100)
    else
        playHit(headshot and 'headshot' or 'hit', dmg > 0 and dmg or 25)
    end

    if headshot and instant and IsPedAPlayer(victim) and now - lastHeadshotAt > 80 then
        lastHeadshotAt = now
        local idx = NetworkGetPlayerIndexFromPed(victim)
        if idx and idx ~= -1 then
            TriggerServerEvent('cursor_arena:server:headshot', GetPlayerServerId(idx))
        end
    end
end)

RegisterNetEvent('cursor_arena:client:forceHeadshot', function()
    if not Arena.Client.inArena then return end
    applyHeadshotKill(PlayerPedId())
end)

RegisterNetEvent('cursor_arena:client:killstreak', function(streak)
    if Arena.Client.muteStreaks then return end
    SendNUIMessage({
        action = 'killstreak',
        style = Config.KillstreakStyle,
        label = streak.label,
        kills = streak.kills,
        team = Arena.Client.team,
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
