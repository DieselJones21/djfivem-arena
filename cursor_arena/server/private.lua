Arena = Arena or {}
Arena.PrivateAdmit = Arena.PrivateAdmit or {}
Arena.PrivateCodes = Arena.PrivateCodes or {}

local LOADOUTS = { 'pistols', 'smg', 'ar' }
local CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

local function cfg()
    return Config.PrivateLobbies or {}
end

local function normalizeCode(code)
    return string.upper((tostring(code or ''):gsub('%s', '')))
end

local function makeCode()
    local len = cfg().codeLength or 5
    for _ = 1, 24 do
        local code = ''
        for i = 1, len do
            local n = math.random(#CODE_CHARS)
            code = code .. CODE_CHARS:sub(n, n)
        end
        if not Arena.PrivateCodes[code] then
            return code
        end
    end
end

local function ownerCount(src)
    local n = 0
    for _, lobby in pairs(Arena.Lobbies) do
        if lobby.private and lobby.owner == src then
            n = n + 1
        end
    end
    return n
end

local function mapsFor(mode)
    if mode == 'ffa' or mode == 'tdm' then
        return Config.FfaMaps or { 'arena_1', 'arena_2' }
    end
    return Config.PvpMaps or { 'pvp_1', 'pvp_2', 'pvp_3', 'pvp_4' }
end

local function allowedMap(mode, mapId)
    local list = mapsFor(mode)
    for i = 1, #list do
        if list[i] == mapId then return true end
    end
    return false
end

local function clampFirstTo(mode, value)
    local options = (cfg().firstTo or {})[mode] or { 5 }
    local n = tonumber(value)
    if not n then return options[#options] or options[1] end
    local best = options[1]
    local dist = math.abs(n - best)
    for i = 1, #options do
        local d = math.abs(n - options[i])
        if d < dist then
            best, dist = options[i], d
        end
    end
    return best
end

local function buildCfg(opts)
    local kind = opts.mode
    local mapId = opts.mapId or opts.map
    if kind == '1v1' or kind == '2v2' or kind == '3v3' or kind == '4v4' then
        opts.size = tonumber(kind:sub(1, 1))
        kind = 'pvp'
    end
    if kind ~= 'ffa' and kind ~= 'tdm' and kind ~= 'pvp' then
        return nil, 'cannot_join'
    end
    if not allowedMap(kind, mapId) then
        return nil, 'not_found'
    end

    local firstTo = clampFirstTo(kind, opts.firstTo)
    if kind == 'ffa' then
        return {
            id = '',
            name = 'Private FFA',
            description = 'Private free-for-all.',
            map = mapId,
            maxPlayers = 12,
            killsToWin = firstTo,
            loadouts = LOADOUTS,
            kill_rewards = { health = 25 },
            sizeLabel = 'FFA',
            private = true,
        }, 'ffa'
    end
    if kind == 'tdm' then
        return {
            id = '',
            name = 'Private TDM',
            description = 'Private Orange vs Blue.',
            map = mapId,
            maxPlayersPerTeam = 5,
            killsToWin = firstTo,
            loadouts = LOADOUTS,
            kill_rewards = { health = 20 },
            win_rewards = { money = 500 },
            teamkill = false,
            sizeLabel = 'TDM',
            private = true,
        }, 'tdm'
    end

    local size = tonumber(opts.size) or 1
    if size < 1 then size = 1 end
    if size > 4 then size = 4 end
    return {
        id = '',
        name = ('%sv%s'):format(size, size),
        description = 'Private elimination.',
        map = mapId,
        maxPlayersPerTeam = size,
        roundsToWin = firstTo,
        roundTime = 90 + (size * 15),
        loadouts = LOADOUTS,
        teamkill = false,
        joinDuringMatch = false,
        sizeLabel = ('%sv%s'):format(size, size),
        win_rewards = { money = 250 * size },
        private = true,
    }, 'pvp'
end

function Arena.FindByCode(code)
    code = normalizeCode(code)
    local id = Arena.PrivateCodes[code]
    return id and Arena.Lobbies[id]
end

function Arena.AdmitPrivate(src, lobbyId)
    Arena.PrivateAdmit[src] = { id = lobbyId, until = os.time() + 45 }
end

function Arena.DestroyPrivate(lobbyId)
    local lobby = Arena.Lobbies[lobbyId]
    if not lobby or not lobby.private then return false end
    if Arena.Watch and Arena.Watch.Clear then
        Arena.Watch.Clear(lobbyId)
    end
    if lobby.code then
        Arena.PrivateCodes[lobby.code] = nil
    end
    Arena.Lobbies[lobbyId] = nil
    Arena.MarkLobbiesDirty()
    return true
end

function Arena.CreatePrivate(src, opts)
    opts = opts or {}
    if cfg().enabled == false then
        return false, 'private_disabled'
    end
    if not Arena.EnsurePlayerHub(src) then
        return false, 'must_be_in_hub'
    end
    if Arena.PlayerLobby and Arena.PlayerLobby[src] then
        return false, 'already_in_match'
    end
    if ownerCount(src) >= (cfg().maxPerPlayer or 1) then
        return false, 'private_full'
    end

    local lobbyCfg, mode = buildCfg(opts)
    if not lobbyCfg then
        return false, mode or 'cannot_join'
    end

    local map = Config.GetMap(lobbyCfg.map)
    if not map then return false, 'not_found' end

    local code = makeCode()
    if not code then return false, 'cannot_join' end

    local id = ('priv_%s_%s'):format(code:lower(), src)
    lobbyCfg.id = id

    local bucket = Arena.AllocBucket()
    local lobby = {
        id = id,
        mode = mode,
        cfg = lobbyCfg,
        map = map,
        bucket = bucket,
        voiceOffset = Arena.AllocVoice(),
        players = {},
        state = 'idle',
        scores = { [1] = 0, [2] = 0 },
        round = 1,
        decks = {},
        private = true,
        owner = src,
        code = code,
    }
    Arena.ResetDecks(lobby)
    Arena.LockBucket(bucket)
    Arena.Lobbies[id] = lobby
    Arena.PrivateCodes[code] = id
    Arena.AdmitPrivate(src, id)

    local ok, result = Arena.JoinLobby(src, id, {
        team = opts.team,
        loadoutId = opts.loadoutId,
        weaponId = opts.weaponId,
        viaCode = true,
    })
    if not ok then
        Arena.DestroyPrivate(id)
        return false, result
    end

    Arena.Utils.Notify(src, { type = 'success', description = L('private_created', code) })
    return true, result
end

function Arena.JoinByCode(src, code, opts)
    opts = opts or {}
    local lobby = Arena.FindByCode(code)
    if not lobby then return false, 'bad_code' end
    Arena.AdmitPrivate(src, lobby.id)
    opts.viaCode = true
    return Arena.JoinLobby(src, lobby.id, opts)
end

function Arena.WatchByCode(src, code)
    local lobby = Arena.FindByCode(code)
    if not lobby then return false, 'bad_code' end
    Arena.AdmitPrivate(src, lobby.id)
    return Arena.Watch.Join(src, lobby.id)
end

AddEventHandler('playerDropped', function()
    local src = source
    Arena.PrivateAdmit[src] = nil
    for id, lobby in pairs(Arena.Lobbies or {}) do
        if lobby.private and lobby.owner == src and Arena.CountPlayers(lobby) == 0 then
            Arena.DestroyPrivate(id)
        end
    end
end)
