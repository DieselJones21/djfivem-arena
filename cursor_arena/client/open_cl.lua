--[[ Editable client hooks ]]

function PlayerJoinedLobby() end -- luacheck: ignore
function PlayerLeftLobby() end -- luacheck: ignore

function GiveKillReward(rewards)
    if not rewards then return end
    local ped = PlayerPedId()
    if rewards.health and rewards.health > 0 then
        SetEntityHealth(ped, math.min(GetEntityMaxHealth(ped), GetEntityHealth(ped) + rewards.health))
    end
    if rewards.armor and rewards.armor > 0 then
        SetPedArmour(ped, math.min(100, GetPedArmour(ped) + rewards.armor))
    end
end

function KillstreakReward(streak)
    if not streak or not streak.reward then return end
    local ped = PlayerPedId()
    if streak.reward == 'armor' then
        SetPedArmour(ped, math.min(100, (streak.amount or 100)))
    elseif streak.reward == 'speed' then
        local seconds = streak.seconds or 20
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.25)
        SetTimeout(seconds * 1000, function()
            SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        end)
    end
end

function ArenaBanner(title, message, notifType, duration)
    lib.notify({
        title = title,
        description = message,
        type = notifType or 'inform',
        duration = duration or 4000,
    })
end
