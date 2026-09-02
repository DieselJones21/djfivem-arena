--[[
    Discord display names for lobby cards, HUD, and ranking.
    Falls back to FiveM / character name if Discord is not linked.
]]

Arena = Arena or {}
Arena.Names = { cache = {} }

local function discordId(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:sub(1, 8) == 'discord:' then
            return id:sub(9)
        end
    end
end

local function fromExports(src, id)
    local tries = {
        { 'Badger_Discord_API', 'GetDiscordName' },
        { 'Badger_Discord_API', 'GetDiscordNickname' },
        { 'discord_perms', 'GetDiscordName' },
        { 'zdiscord', 'GetPlayerName' },
    }
    for i = 1, #tries do
        local res, exp = tries[i][1], tries[i][2]
        if GetResourceState(res) == 'started' then
            local ok, name = pcall(function()
                return exports[res][exp](exports[res], src, id)
            end)
            if (not ok or type(name) ~= 'string' or name == '') and id then
                ok, name = pcall(function()
                    return exports[res][exp](exports[res], id)
                end)
            end
            if ok and type(name) == 'string' and name ~= '' then
                return name
            end
        end
    end
end

local function fallbackName(src)
    if GetArenaDisplayName then
        local n = GetArenaDisplayName(src)
        if type(n) == 'string' and n ~= '' then return n end
    end
    local player = Arena.Framework.GetPlayer and Arena.Framework.GetPlayer(src)
    if player then
        local fw = Arena.Framework.name
        if fw == 'esx' and player.getName then
            return player.getName()
        elseif (fw == 'qb' or fw == 'qbx') and player.PlayerData and player.PlayerData.charinfo then
            local info = player.PlayerData.charinfo
            local n = ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
            if n ~= '' then return n end
        end
    end
    return GetPlayerName(src) or ('Player %s'):format(src)
end

local function applyName(src, name)
    if type(name) ~= 'string' or name == '' then return end
    Arena.Names.cache[src] = name
    local lobby = Arena.GetPlayerLobby and Arena.GetPlayerLobby(src)
    if lobby and lobby.players and lobby.players[src] and Arena.PublicLobby then
        lobby.players[src].name = name
        local data = Arena.PublicLobby(lobby)
        for id in pairs(lobby.players) do
            TriggerClientEvent('cursor_arena:client:lobbySync', id, data)
        end
        TriggerClientEvent('cursor_arena:client:lobbiesDirty', -1)
    end
end

local function fetchDiscord(src, id)
    local token = (DiscordNames and DiscordNames.botToken) or GetConvar('cursor_arena:discord_token', '')
    if not token or token == '' then return end
    PerformHttpRequest(('https://discord.com/api/v10/users/%s'):format(id), function(code, body)
        if code ~= 200 or not body then return end
        local ok, data = pcall(json.decode, body)
        if not ok or type(data) ~= 'table' then return end
        local name = data.global_name or data.username
        if DiscordNames and DiscordNames.preferGlobalName == false then
            name = data.username or data.global_name
        end
        applyName(src, name)
    end, 'GET', '', {
        ['Authorization'] = 'Bot ' .. token,
    })
end

function Arena.Names.Resolve(src)
    if Arena.Names.cache[src] then return Arena.Names.cache[src] end
    local id = discordId(src)
    local exported = fromExports(src, id)
    if exported then
        Arena.Names.cache[src] = exported
        return exported
    end
    local name = fallbackName(src)
    Arena.Names.cache[src] = name
    if id and DiscordNames and DiscordNames.enabled ~= false then
        fetchDiscord(src, id)
    end
    return name
end

local originalGetName = Arena.Framework.GetName
function Arena.Framework.GetName(src)
    return Arena.Names.Resolve(src) or (originalGetName and originalGetName(src)) or GetPlayerName(src)
end

AddEventHandler('playerDropped', function()
    Arena.Names.cache[source] = nil
end)
