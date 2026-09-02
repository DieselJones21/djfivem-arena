Arena = Arena or {}
Arena.Discord = {}

local function enabledFor(mode)
    if not ArenaDiscord or not ArenaDiscord.enabled then return false end
    if not ArenaDiscord.url or ArenaDiscord.url == '' then return false end
    if mode == 'ffa' then return ArenaDiscord.ffa ~= false end
    if mode == 'tdm' then return ArenaDiscord.tdm ~= false end
    if mode == 'showdown' then return ArenaDiscord.showdown ~= false end
    return true
end

function Arena.Discord.MatchEnded(mode, result)
    if not enabledFor(mode) then return end

    local lines = {}
    for i = 1, #(result.players or {}) do
        local p = result.players[i]
        local tag = p.won and 'W' or 'L'
        lines[#lines + 1] = ('`%s` %s  %s/%s  %s'):format(
            tag,
            p.name or 'Unknown',
            p.kills or 0,
            p.deaths or 0,
            p.eloChange and ((p.eloChange >= 0 and '+' or '') .. p.eloChange) or ''
        )
    end

    local winner = 'Draw'
    if result.winnerSrc then
        winner = result.winnerName or ('ID ' .. result.winnerSrc)
    elseif result.winner == 1 then
        winner = 'Orange'
    elseif result.winner == 2 then
        winner = 'Blue'
    end

    local color = mode == 'ffa' and 16721408 or (mode == 'tdm' and 3900159 or 11038711)
    local payload = {
        username = ArenaDiscord.name or 'Arena',
        avatar_url = ArenaDiscord.avatar ~= '' and ArenaDiscord.avatar or nil,
        embeds = {{
            title = result.name or 'Arena match',
            description = ('**%s**  ·  %s  ·  winner: **%s**'):format(
                mode:upper(),
                result.scoreline or '',
                winner
            ),
            color = color,
            fields = {{
                name = 'Roster',
                value = #lines > 0 and table.concat(lines, '\n') or '_empty_',
            }},
            footer = { text = 'cursor_arena' },
        }},
    }

    PerformHttpRequest(ArenaDiscord.url, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
    })
end
