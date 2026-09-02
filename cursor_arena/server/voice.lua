Arena = Arena or {}
Arena.Voice = {}

local function pmaReady()
    return Config.SquadVoice.enabled and GetResourceState('pma-voice') == 'started'
end

function Arena.Voice.ChannelFor(lobby, team)
    if not pmaReady() then return 0 end
    local base = Config.SquadVoice.channel + (lobby.voiceOffset or 0)
    if team == 2 then return base + 1 end
    return base
end

function Arena.Voice.Join(src, lobby, team)
    if not pmaReady() then return end
    if not Arena.Utils.IsTeamMode(lobby.mode) then return end
    local channel = Arena.Voice.ChannelFor(lobby, team)
    pcall(function()
        exports['pma-voice']:setPlayerRadio(src, channel)
    end)
    TriggerClientEvent('cursor_arena:client:voice', src, channel)
end

function Arena.Voice.Leave(src)
    if not pmaReady() then
        TriggerClientEvent('cursor_arena:client:voice', src, 0)
        return
    end
    pcall(function()
        exports['pma-voice']:setPlayerRadio(src, 0)
    end)
    TriggerClientEvent('cursor_arena:client:voice', src, 0)
end
