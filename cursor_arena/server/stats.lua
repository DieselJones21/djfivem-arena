Arena = Arena or {}
Arena.Stats = {}

local STATS_KEY = 'cursor_arena:stats'
local statsCache = nil
local dirty = false

local function loadStats()
    if statsCache then return statsCache end
    local raw = GetResourceKvpString(STATS_KEY)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            statsCache = data
            return statsCache
        end
    end
    statsCache = {}
    return statsCache
end

local function saveStats()
    if not statsCache then return end
    SetResourceKvp(STATS_KEY, json.encode(statsCache))
    dirty = false
end

CreateThread(function()
    loadStats()
    while true do
        Wait(60000)
        if dirty then saveStats() end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and dirty then
        saveStats()
    end
end)

local function ensurePlayer(id, name)
    local all = loadStats()
    if not all[id] then
        all[id] = {
            name = name or 'Unknown',
            kills = 0,
            deaths = 0,
            wins = 0,
            losses = 0,
            elo = 1000,
            gang = '',
        }
        dirty = true
    elseif name and name ~= '' then
        all[id].name = name
    end
    return all[id]
end

function Arena.Stats.RecordKill(killerSrc, victimSrc)
    if killerSrc and killerSrc > 0 then
        local kid = Arena.Framework.GetIdentifier(killerSrc)
        local row = ensurePlayer(kid, Arena.Framework.GetName(killerSrc))
        row.kills = (row.kills or 0) + 1
        row.elo = (row.elo or 1000) + 3
        dirty = true
    end
    if victimSrc and victimSrc > 0 then
        local vid = Arena.Framework.GetIdentifier(victimSrc)
        local row = ensurePlayer(vid, Arena.Framework.GetName(victimSrc))
        row.deaths = (row.deaths or 0) + 1
        row.elo = math.max(0, (row.elo or 1000) - 1)
        dirty = true
    end
end

function Arena.Stats.RecordMatchResult(src, won)
    local id = Arena.Framework.GetIdentifier(src)
    local row = ensurePlayer(id, Arena.Framework.GetName(src))
    if won then
        row.wins = (row.wins or 0) + 1
        row.elo = (row.elo or 1000) + 15
    else
        row.losses = (row.losses or 0) + 1
        row.elo = math.max(0, (row.elo or 1000) - 8)
    end
    dirty = true
end

function Arena.Stats.GetPlayer(src)
    local id = Arena.Framework.GetIdentifier(src)
    return ensurePlayer(id, Arena.Framework.GetName(src))
end

function Arena.Stats.GetLeaderboard(limit)
    limit = limit or 50
    local all = loadStats()
    local list = {}
    for _, row in pairs(all) do
        list[#list + 1] = {
            name = row.name,
            kills = row.kills or 0,
            deaths = row.deaths or 0,
            wins = row.wins or 0,
            losses = row.losses or 0,
            elo = row.elo or 1000,
            gang = row.gang or '',
            kd = (row.deaths or 0) > 0 and math.floor(((row.kills or 0) / row.deaths) * 100) / 100 or (row.kills or 0),
        }
    end
    table.sort(list, function(a, b)
        if a.elo == b.elo then
            return a.kills > b.kills
        end
        return a.elo > b.elo
    end)
    local out = {}
    for i = 1, math.min(limit, #list) do
        out[i] = list[i]
        out[i].rank = i
    end
    return out
end
