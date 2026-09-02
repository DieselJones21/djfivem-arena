Arena = Arena or {}
Arena.Stats = {}

local hasSql = false
local kvpCache = { stats = {}, matches = {}, dirty = false }

local function sqlReady()
    return GetResourceState('oxmysql') == 'started' and MySQL ~= nil
end

local function kvpLoad()
    local raw = GetResourceKvpString('cursor_arena:v2stats')
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            kvpCache.stats = data.stats or {}
            kvpCache.matches = data.matches or {}
            return
        end
    end
    kvpCache.stats = {}
    kvpCache.matches = {}
end

local function kvpSave()
    SetResourceKvp('cursor_arena:v2stats', json.encode({
        stats = kvpCache.stats,
        matches = kvpCache.matches,
    }))
    kvpCache.dirty = false
end

CreateThread(function()
    Wait(200)
    if sqlReady() then
        local ok, err = pcall(function()
        hasSql = true
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS cursor_arena_stats (
                identifier VARCHAR(64) NOT NULL,
                mode VARCHAR(32) NOT NULL,
                name VARCHAR(64) DEFAULT '',
                kills INT DEFAULT 0,
                deaths INT DEFAULT 0,
                wins INT DEFAULT 0,
                losses INT DEFAULT 0,
                matches INT DEFAULT 0,
                playtime INT DEFAULT 0,
                elo INT DEFAULT 1000,
                PRIMARY KEY (identifier, mode)
            )
        ]])
        MySQL.query.await([[
            CREATE TABLE IF NOT EXISTS cursor_arena_matches (
                id INT AUTO_INCREMENT PRIMARY KEY,
                match_uid VARCHAR(64),
                identifier VARCHAR(64),
                name VARCHAR(64),
                mode VARCHAR(32),
                lobby_id VARCHAR(64),
                lobby_name VARCHAR(128),
                kills INT DEFAULT 0,
                deaths INT DEFAULT 0,
                won TINYINT DEFAULT 0,
                team INT DEFAULT 0,
                place INT DEFAULT 0,
                elo_change INT DEFAULT 0,
                scoreline VARCHAR(32) DEFAULT '',
                duration INT DEFAULT 0,
                roster LONGTEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ]])
        local days = Config.MatchHistoryDays or 7
        MySQL.query(('DELETE FROM cursor_arena_matches WHERE created_at < DATE_SUB(NOW(), INTERVAL %s DAY)'):format(tonumber(days) or 7))
        Arena.Utils.Debug('oxmysql stats tables ready')
        end)
        if not ok then
            hasSql = false
            print('[cursor_arena] oxmysql init failed, using KVP:', err)
            kvpLoad()
        end
    else
        kvpLoad()
        Arena.Utils.Debug('oxmysql missing — using KVP stats fallback')
    end
end)

CreateThread(function()
    while true do
        Wait(60000)
        if not hasSql and kvpCache.dirty then kvpSave() end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and not hasSql and kvpCache.dirty then
        kvpSave()
    end
end)

local function defaultRow(name)
    return {
        name = name or 'Unknown',
        kills = 0, deaths = 0, wins = 0, losses = 0,
        matches = 0, playtime = 0, elo = Config.Elo.start or 1000,
    }
end

function Arena.Stats.GetRow(identifier, mode, name)
    mode = mode or 'ffa'
    if hasSql then
        local row = MySQL.single.await('SELECT * FROM cursor_arena_stats WHERE identifier = ? AND mode = ?', { identifier, mode })
        if not row then
            MySQL.insert.await('INSERT INTO cursor_arena_stats (identifier, mode, name, elo) VALUES (?, ?, ?, ?)', {
                identifier, mode, name or 'Unknown', Config.Elo.start or 1000,
            })
            row = defaultRow(name)
            row.identifier = identifier
            row.mode = mode
        elseif name and name ~= '' then
            MySQL.update('UPDATE cursor_arena_stats SET name = ? WHERE identifier = ? AND mode = ?', { name, identifier, mode })
            row.name = name
        end
        return row
    end

    kvpCache.stats[identifier] = kvpCache.stats[identifier] or {}
    if not kvpCache.stats[identifier][mode] then
        kvpCache.stats[identifier][mode] = defaultRow(name)
        kvpCache.dirty = true
    elseif name then
        kvpCache.stats[identifier][mode].name = name
    end
    return kvpCache.stats[identifier][mode]
end

function Arena.Stats.GetPlayer(src, mode)
    local id = Arena.Framework.GetIdentifier(src)
    return Arena.Stats.GetRow(id, mode or 'ffa', Arena.Framework.GetName(src))
end

function Arena.Stats.GetAllModes(src)
    local out = {}
    for _, mode in ipairs({ 'ffa', 'tdm', 'pvp', 'showdown' }) do
        out[mode] = Arena.Stats.GetPlayer(src, mode)
    end
    return out
end

local function persistRow(identifier, mode, row)
    if hasSql then
        MySQL.update.await([[
            UPDATE cursor_arena_stats
            SET name=?, kills=?, deaths=?, wins=?, losses=?, matches=?, playtime=?, elo=?
            WHERE identifier=? AND mode=?
        ]], {
            row.name, row.kills, row.deaths, row.wins, row.losses, row.matches, row.playtime, row.elo,
            identifier, mode,
        })
    else
        kvpCache.dirty = true
    end
end

function Arena.Stats.ApplyMatch(src, mode, data)
    local id = Arena.Framework.GetIdentifier(src)
    local row = Arena.Stats.GetRow(id, mode, Arena.Framework.GetName(src))
    row.kills = (row.kills or 0) + (data.kills or 0)
    row.deaths = (row.deaths or 0) + (data.deaths or 0)
    row.matches = (row.matches or 0) + 1
    row.playtime = (row.playtime or 0) + (data.playtime or 0)
    if data.won then
        row.wins = (row.wins or 0) + 1
    else
        row.losses = (row.losses or 0) + 1
    end
    if data.eloChange then
        row.elo = math.max(Config.Elo.floor or 100, (row.elo or 1000) + data.eloChange)
    end
    persistRow(id, mode, row)
    return row
end

function Arena.Stats.RecordHistory(entries)
    if hasSql then
        for i = 1, #entries do
            local e = entries[i]
            MySQL.insert([[
                INSERT INTO cursor_arena_matches
                (match_uid, identifier, name, mode, lobby_id, lobby_name, kills, deaths, won, team, place, elo_change, scoreline, duration, roster)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ]], {
                e.matchUid, e.identifier, e.name, e.mode, e.lobbyId, e.lobbyName,
                e.kills, e.deaths, e.won and 1 or 0, e.team or 0, e.place or 0,
                e.eloChange or 0, e.scoreline or '', e.duration or 0, json.encode(e.roster or {}),
            })
        end
        return
    end
    for i = 1, #entries do
        kvpCache.matches[#kvpCache.matches + 1] = entries[i]
    end
    kvpCache.dirty = true
end

function Arena.Stats.GetHistory(src, limit)
    limit = limit or 20
    local id = Arena.Framework.GetIdentifier(src)
    if hasSql then
        return MySQL.query.await('SELECT * FROM cursor_arena_matches WHERE identifier = ? ORDER BY created_at DESC LIMIT ?', { id, limit }) or {}
    end
    local list = {}
    for i = #kvpCache.matches, 1, -1 do
        if kvpCache.matches[i].identifier == id then
            list[#list + 1] = kvpCache.matches[i]
            if #list >= limit then break end
        end
    end
    return list
end

function Arena.Stats.GetLeaderboard(mode, limit)
    mode = mode or 'ffa'
    limit = limit or 50
    local list = {}

    if hasSql then
        list = MySQL.query.await([[
            SELECT * FROM cursor_arena_stats WHERE mode = ? AND matches > 0
        ]], { mode }) or {}
    else
        for _, modes in pairs(kvpCache.stats) do
            if modes[mode] and (modes[mode].matches or 0) > 0 then
                list[#list + 1] = modes[mode]
            end
        end
    end

    local ranked = mode == 'showdown' or mode == 'pvp'
    table.sort(list, function(a, b)
        if ranked then
            if (a.elo or 0) == (b.elo or 0) then
                return (a.kills or 0) > (b.kills or 0)
            end
            return (a.elo or 0) > (b.elo or 0)
        end
        if (a.kills or 0) == (b.kills or 0) then
            return (a.wins or 0) > (b.wins or 0)
        end
        return (a.kills or 0) > (b.kills or 0)
    end)

    local out = {}
    for i = 1, math.min(limit, #list) do
        local row = list[i]
        local deaths = row.deaths or 0
        out[i] = {
            rank = i,
            name = row.name,
            kills = row.kills or 0,
            deaths = deaths,
            wins = row.wins or 0,
            losses = row.losses or 0,
            matches = row.matches or 0,
            elo = row.elo or 1000,
            kd = deaths > 0 and math.floor(((row.kills or 0) / deaths) * 100) / 100 or (row.kills or 0),
            title = Arena.Utils.TitleForRank(mode, i),
        }
    end
    return out
end

function Arena.Stats.ComputeElo(avgA, avgB, aWon)
    local k = Config.Elo.k or 32
    local expected = 1 / (1 + (10 ^ ((avgB - avgA) / 400)))
    local score = aWon and 1 or 0
    local change = math.floor(k * (score - expected) + 0.5)
    return change
end
