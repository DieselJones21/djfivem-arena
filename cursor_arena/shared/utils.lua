Arena = Arena or {}
Arena.Utils = {}

local function debugPrint(...)
    if Config.Debug then
        print('[cursor_arena]', ...)
    end
end

Arena.Utils.Debug = debugPrint

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

function Arena.Utils.PickSpawn(spawns, usedIndexes)
    usedIndexes = usedIndexes or {}
    if not spawns or #spawns == 0 then return nil end

    for i = 1, #spawns do
        if not usedIndexes[i] then
            usedIndexes[i] = true
            return spawns[i], i, usedIndexes
        end
    end

    -- reuse if exhausted
    local idx = math.random(#spawns)
    return spawns[idx], idx, usedIndexes
end

function Arena.Utils.IsTeamMode(mode)
    return mode and (mode.type == 'tdm' or mode.type == 'team')
end

function Arena.Utils.SerializeMaps()
    local out = {}
    for i = 1, #Config.Maps do
        local m = Config.Maps[i]
        out[#out + 1] = {
            id = m.id,
            label = m.label,
            description = m.description,
            image = m.image,
            modes = m.modes,
        }
    end
    return out
end

function Arena.Utils.SerializeModes()
    local out = {}
    for i = 1, #Config.Modes do
        local m = Config.Modes[i]
        out[#out + 1] = {
            id = m.id,
            label = m.label,
            description = m.description,
            type = m.type,
            icon = m.icon,
            weaponCategory = m.weaponCategory,
            allowWeaponChoice = m.allowWeaponChoice,
            minPlayers = m.minPlayers,
            maxPlayers = m.maxPlayers,
            scoreLimit = m.scoreLimit,
            timeLimit = m.timeLimit,
            teamSize = m.teamSize,
            rounds = m.rounds,
            color = m.color,
            tab = m.tab,
            style = m.style,
        }
    end
    return out
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
