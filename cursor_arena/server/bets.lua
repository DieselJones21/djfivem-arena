Arena = Arena or {}
Arena.Bets = Arena.Bets or {}
Arena.Watch = Arena.Watch or {}

Arena.Watchers = Arena.Watchers or {}
Arena.Watching = Arena.Watching or {}
Arena.Tickets = Arena.Tickets or {}

local function cfg()
    return Config.Betting or {}
end

local function tickets(lobbyId)
    Arena.Tickets[lobbyId] = Arena.Tickets[lobbyId] or {}
    return Arena.Tickets[lobbyId]
end

local function watchers(lobbyId)
    Arena.Watchers[lobbyId] = Arena.Watchers[lobbyId] or {}
    return Arena.Watchers[lobbyId]
end

function Arena.Watch.Count(lobbyId)
    return Arena.Utils.TableSize(watchers(lobbyId))
end

function Arena.Watch.IsWatching(src)
    return Arena.Watching[src]
end

function Arena.Watch.Join(src, lobbyId)
    if not Arena.PlayerHub[src] then return false, 'must_be_in_hub' end
    if Arena.PlayerLobby[src] then return false, 'already_in_match' end
    local lobby = Arena.Lobbies[lobbyId]
    if not lobby then return false, 'not_found' end
    if lobby.state ~= 'active' and lobby.state ~= 'countdown' and lobby.state ~= 'waiting' then
        return false, 'not_found'
    end
    if lobby.private then
        local admit = Arena.PrivateAdmit and Arena.PrivateAdmit[src]
        local allowed = src == lobby.owner
            or (admit and admit.id == lobbyId and os.time() <= (admit.until or 0))
        if not allowed then
            return false, 'bad_code'
        end
    end

    Arena.Watch.Leave(src, true)
    watchers(lobbyId)[src] = true
    Arena.Watching[src] = lobbyId
    SetPlayerRoutingBucket(src, lobby.bucket)
    local ply = Player(src)
    if ply and ply.state then
        ply.state:set('arena_spectator', true, true)
        ply.state:set('invBusy', false, true)
    end
    TriggerClientEvent('cursor_arena:client:watchStart', src, Arena.PublicLobby(lobby, src))
    return true, Arena.PublicLobby(lobby, src)
end

function Arena.Watch.Leave(src, silent)
    local lobbyId = Arena.Watching[src]
    if not lobbyId then return false end
    Arena.Watching[src] = nil
    if Arena.Watchers[lobbyId] then
        Arena.Watchers[lobbyId][src] = nil
    end
    SetPlayerRoutingBucket(src, 0)
    local ply = Player(src)
    if ply and ply.state then
        ply.state:set('arena_spectator', false, true)
    end
    Arena.PlayerHub[src] = true
    TriggerClientEvent('cursor_arena:client:watchStop', src, { silent = silent == true })
    return true
end

function Arena.Watch.Clear(lobbyId)
    local list = watchers(lobbyId)
    local srcs = {}
    for src in pairs(list) do srcs[#srcs + 1] = src end
    for i = 1, #srcs do
        Arena.Watch.Leave(srcs[i], true)
    end
    Arena.Watchers[lobbyId] = {}
end

local function itemKind(name)
    local n = tostring(name or ''):lower()
    if n:find('weapon') or n:find('pistol') or n:find('rifle') or n:find('smg') then
        return 'gun'
    end
    if n:find('vehicle') or n:find('car') or n:find('key') or n:find('plate') or n:find('auto') then
        return 'car'
    end
    return 'item'
end

function Arena.Bets.ListItems(src)
    if GetResourceState('ox_inventory') ~= 'started' then return {} end
    local ok, items = pcall(function()
        return exports.ox_inventory:GetInventoryItems(src)
    end)
    if not ok or type(items) ~= 'table' then return {} end
    local out = {}
    for _, row in pairs(items) do
        if type(row) == 'table' and row.name and (row.count or 0) > 0 then
            out[#out + 1] = {
                name = row.name,
                label = row.label or row.name,
                count = row.count,
                slot = row.slot,
                kind = itemKind(row.name),
            }
        end
    end
    table.sort(out, function(a, b) return a.label < b.label end)
    return out
end

function Arena.Bets.List(lobbyId)
    local list = {}
    for i = 1, #tickets(lobbyId) do
        local t = tickets(lobbyId)[i]
        list[#list + 1] = {
            src = t.src,
            name = t.name,
            pickSrc = t.pickSrc,
            pickName = t.pickName,
            cash = t.cash,
            items = t.items,
        }
    end
    return list
end

local function takeItems(src, wanted)
    if not wanted or #wanted == 0 then return {} end
    if GetResourceState('ox_inventory') ~= 'started' then return end
    local held = {}
    for i = 1, #wanted do
        local row = wanted[i]
        local name = row.name
        local count = math.max(1, math.floor(tonumber(row.count) or 1))
        if not name or not Arena.Framework.HasItem(src, name, count) then
            for j = 1, #held do
                exports.ox_inventory:AddItem(src, held[j].name, held[j].count, held[j].metadata)
            end
            return
        end
        local ok = pcall(function()
            exports.ox_inventory:RemoveItem(src, name, count)
        end)
        if not ok then
            for j = 1, #held do
                exports.ox_inventory:AddItem(src, held[j].name, held[j].count, held[j].metadata)
            end
            return
        end
        held[#held + 1] = { name = name, count = count, kind = itemKind(name) }
    end
    return held
end

local function giveItems(src, items)
    if not items then return end
    for i = 1, #items do
        pcall(function()
            exports.ox_inventory:AddItem(src, items[i].name, items[i].count or 1)
        end)
    end
end

function Arena.Bets.Place(src, lobbyId, data)
    local betCfg = cfg()
    if betCfg.enabled == false then return false, 'bet_invalid' end
    if Arena.PlayerLobby[src] then return false, 'already_in_match' end
    if not Arena.PlayerHub[src] and not Arena.Watching[src] then return false, 'must_be_in_hub' end
    local lobby = Arena.Lobbies[lobbyId]
    if not lobby then return false, 'not_found' end
    if lobby.state ~= 'waiting' and lobby.state ~= 'countdown' and lobby.state ~= 'active' then
        return false, 'bet_invalid'
    end

    local pickSrc = tonumber(data and data.pickSrc)
    local pick = pickSrc and lobby.players[pickSrc]
    if not pick then return false, 'bet_invalid' end

    local cash = math.floor(tonumber(data and data.cash) or 0)
    local maxCash = betCfg.maxCash or 100000
    local minCash = betCfg.minCash or 100
    if cash < 0 or cash > maxCash then return false, 'bet_max' end
    if cash > 0 and cash < minCash then return false, 'bet_invalid' end

    local items
    if betCfg.allowItems ~= false and data and data.items then
        items = takeItems(src, data.items)
        if data.items[1] and not items then return false, 'bet_invalid' end
    end
    items = items or {}
    if cash <= 0 and #items == 0 then return false, 'bet_invalid' end

    if cash > 0 and not Arena.Framework.RemoveMoney(src, cash) then
        giveItems(src, items)
        return false, 'bet_broke'
    end

    tickets(lobbyId)[#tickets(lobbyId) + 1] = {
        src = src,
        name = Arena.Framework.GetName(src),
        pickSrc = pickSrc,
        pickName = pick.name,
        cash = cash,
        items = items,
    }
    return true
end

local function refund(ticket)
    if ticket.cash and ticket.cash > 0 then
        Arena.Framework.AddMoney(ticket.src, ticket.cash)
    end
    giveItems(ticket.src, ticket.items)
end

function Arena.Bets.Settle(lobby, result)
    local lobbyId = lobby.id
    local pot = tickets(lobbyId)
    if #pot == 0 then return end

    local winners = {}
    if result and not result.draw then
        if result.winnerSrc then
            winners[result.winnerSrc] = true
        elseif result.winner == 1 or result.winner == 2 then
            for src, p in pairs(lobby.players) do
                if p.team == result.winner then winners[src] = true end
            end
        end
    end

    local winning, losing = {}, {}
    for i = 1, #pot do
        local t = pot[i]
        if winners[t.pickSrc] then
            winning[#winning + 1] = t
        else
            losing[#losing + 1] = t
        end
    end

    if #winning == 0 or result.draw then
        for i = 1, #pot do
            refund(pot[i])
            Arena.Utils.Notify(pot[i].src, { type = 'inform', description = L('bet_refund') })
        end
        Arena.Tickets[lobbyId] = {}
        return
    end

    local cashPot = 0
    local itemPot = {}
    for i = 1, #losing do
        cashPot = cashPot + (losing[i].cash or 0)
        for j = 1, #(losing[i].items or {}) do
            itemPot[#itemPot + 1] = losing[i].items[j]
        end
    end

    local share = #winning > 0 and math.floor(cashPot / #winning) or 0
    for i = 1, #winning do
        local t = winning[i]
        if t.cash and t.cash > 0 then
            Arena.Framework.AddMoney(t.src, t.cash)
        end
        if share > 0 then
            Arena.Framework.AddMoney(t.src, share)
        end
        giveItems(t.src, t.items)
        Arena.Utils.Notify(t.src, { type = 'success', description = L('bet_won') })
    end

    for i = 1, #itemPot do
        local dest = winning[((i - 1) % #winning) + 1]
        giveItems(dest.src, { itemPot[i] })
    end

    for i = 1, #losing do
        Arena.Utils.Notify(losing[i].src, { type = 'inform', description = L('bet_lost') })
    end
    Arena.Tickets[lobbyId] = {}
end

AddEventHandler('playerDropped', function()
    local src = source
    Arena.Watch.Leave(src, true)
end)
