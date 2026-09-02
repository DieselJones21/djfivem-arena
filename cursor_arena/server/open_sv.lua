--[[
    Editable hooks — survive your own updates. Return false to block a join/leave.
]]

-- Discord display name override. Return a string to skip the built-in Discord lookup.
function GetArenaDisplayName(playerId) -- luacheck: ignore
    return nil
end

-- Same coins as the Envy Donator Store. Return a number from your resource.
function GetDonatorBalance(playerId) -- luacheck: ignore
    return nil
end

-- Charge arena shop purchases. Return true if the coins were taken.
function RemoveDonatorCurrency(playerId, amount) -- luacheck: ignore
    return nil
end

function CanPlayerJoinLobby(playerId, lobbyId) -- luacheck: ignore
    return true
end

function CanPlayerLeaveLobby(playerId, lobbyId) -- luacheck: ignore
    return true
end

function PlayerJoinedLobby(playerId, lobbyId) end -- luacheck: ignore
function PlayerLeftLobby(playerId, lobbyId) end -- luacheck: ignore
function PlayerLeftServer(playerId) end -- luacheck: ignore

--[[
    Fires once when a match finishes, after stats and rewards.
      mode              'ffa' | 'tdm' | 'showdown'
      result.lobby      lobby id
      result.name       lobby name
      result.winner     1 or 2 in a team mode, 0 for a draw
      result.winnerSrc  who won a free-for-all
      result.players    { src, name, kills, deaths, won, team, place, eloChange }
]]
function MatchEnded(matchId, mode, result) -- luacheck: ignore
end

function GiveItemRewards(playerId, rewards)
    if not rewards or not rewards.items then return end
    if GetResourceState('ox_inventory') ~= 'started' then return end
    for i = 1, #rewards.items do
        local row = rewards.items[i]
        if row and row.item then
            local chance = row.chance or 100
            if math.random(100) <= chance then
                local min = row.min or 1
                local max = row.max or min
                local count = math.random(min, max)
                exports.ox_inventory:AddItem(playerId, row.item, count)
            end
        end
    end
end
