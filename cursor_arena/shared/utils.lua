Arena = Arena or {}
Arena.Utils = {}

function Arena.Utils.Debug(...)
    if Config.Debug then
        print('[cursor_arena]', ...)
    end
end

function Arena.Utils.Notify(src, data)
    if src then
        TriggerClientEvent('ox_lib:notify', src, data)
    else
        lib.notify(data)
    end
end

function Arena.Utils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        copy[k] = Arena.Utils.DeepCopy(v)
    end
    return copy
end

function Arena.Utils.TableSize(tbl)
    local n = 0
    for _ in pairs(tbl) do n = n + 1 end
    return n
end

function Arena.Utils.Shuffle(list)
    local t = {}
    for i = 1, #list do t[i] = list[i] end
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
    return t
end

function Arena.Utils.IsTeamMode(mode)
    return mode == 'tdm' or mode == 'showdown' or mode == 'pvp'
end

function Arena.Utils.IsElimination(mode)
    return mode == 'showdown' or mode == 'pvp'
end

function Arena.Utils.Vec4(coords)
    if not coords then return end
    return {
        x = coords.x or coords[1],
        y = coords.y or coords[2],
        z = coords.z or coords[3],
        w = coords.w or coords[4] or 0.0,
    }
end

--- Point in polygon (ray casting). points are vector2 / {x,y}
function Arena.Utils.PointInPolygon(x, y, points)
    if not points or #points < 3 then return true end
    local inside = false
    local j = #points
    for i = 1, #points do
        local xi, yi = points[i].x, points[i].y
        local xj, yj = points[j].x, points[j].y
        local intersect = ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / ((yj - yi) + 0.0000001) + xi)
        if intersect then inside = not inside end
        j = i
    end
    return inside
end

function Arena.Utils.InsideMap(coords, map)
    if not map or not coords then return true end
    local x, y, z = coords.x, coords.y, coords.z
    local bounds = map.boundaries
    if bounds and bounds.points and #bounds.points >= 3 then
        if bounds.minZ and z < bounds.minZ then return false end
        if bounds.maxZ and z > bounds.maxZ then return false end
        return Arena.Utils.PointInPolygon(x, y, bounds.points)
    end
    if map.center and map.radius then
        local dx = x - map.center.x
        local dy = y - map.center.y
        return (dx * dx + dy * dy) <= (map.radius * map.radius)
    end
    return true
end

function Arena.Utils.CreateSpawnDeck(spawns)
    local deck = { list = {}, cursor = 1 }
    if not spawns or #spawns == 0 then return deck end
    deck.list = Arena.Utils.Shuffle(spawns)
    return deck
end

function Arena.Utils.DealSpawn(deck, fallback)
    if not deck or not deck.list or #deck.list == 0 then
        return fallback
    end
    if deck.cursor > #deck.list then
        deck.list = Arena.Utils.Shuffle(deck.list)
        deck.cursor = 1
    end
    local spawn = deck.list[deck.cursor]
    deck.cursor = deck.cursor + 1
    return spawn
end

function Arena.Utils.TitleForRank(mode, rank)
    local titles = Config.LeaderboardTitles[mode] or Config.LeaderboardTitles.default or {}
    local best
    for i = 1, #titles do
        if rank <= titles[i].rank then
            if not best or titles[i].rank < best.rank then
                best = titles[i]
            end
        end
    end
    return best and best.title or nil
end

function Arena.Utils.SerializeLoadouts()
    local out = {}
    for i = 1, #Config.Loadouts do
        local l = Config.Loadouts[i]
        out[#out + 1] = {
            id = l.id,
            label = l.label,
            description = l.description,
            icon = l.icon,
            category = l.category,
            weapons = l.weapons,
        }
    end
    return out
end

function Arena.Utils.SerializeMaps()
    local out = {}
    for i = 1, #Config.Maps do
        local m = Config.Maps[i]
        out[#out + 1] = {
            id = m.id,
            name = m.name,
            description = m.description,
            image = m.image,
        }
    end
    return out
end

function Arena.Utils.WeaponCategory(weaponName)
    if not weaponName then return 'generic' end
    local key = weaponName:upper()
    return Config.WeaponCategories[key] or 'generic'
end

function Arena.Utils.KillstreakFor(kills)
    local best
    for i = 1, #Config.Killstreaks do
        local row = Config.Killstreaks[i]
        if kills >= row.kills then
            best = row
        end
    end
    return best
end

function Arena.Utils.Locale(key, ...)
    local lang = Locales and Locales[Config.Locale] or Locales and Locales.en
    if not lang then return key end
    local str = lang[key] or (Locales.en and Locales.en[key]) or key
    if select('#', ...) > 0 then
        return str:format(...)
    end
    return str
end

L = Arena.Utils.Locale
