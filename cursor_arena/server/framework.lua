Arena = Arena or {}
Arena.Framework = { name = 'standalone' }

local function detectFramework()
    local configured = Config.Framework
    if configured and configured ~= 'auto' then
        return configured
    end
    if GetResourceState('qbx_core') == 'started' then return 'qbx' end
    if GetResourceState('qb-core') == 'started' then return 'qb' end
    if GetResourceState('es_extended') == 'started' then return 'esx' end
    if GetResourceState('ox_core') == 'started' then return 'ox' end
    return 'standalone'
end

CreateThread(function()
    Wait(400)
    Arena.Framework.name = detectFramework()
    Arena.Utils.Debug('Framework:', Arena.Framework.name)
end)

function Arena.Framework.GetPlayer(src)
    local fw = Arena.Framework.name
    if fw == 'esx' then
        return exports['es_extended']:getSharedObject().GetPlayerFromId(src)
    elseif fw == 'qb' then
        return exports['qb-core']:GetCoreObject().Functions.GetPlayer(src)
    elseif fw == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    end
end

function Arena.Framework.GetName(src)
    local player = Arena.Framework.GetPlayer(src)
    local fw = Arena.Framework.name
    if player then
        if fw == 'esx' then
            return player.getName and player.getName() or GetPlayerName(src)
        elseif fw == 'qb' or fw == 'qbx' then
            local info = player.PlayerData and player.PlayerData.charinfo
            if info then
                return ('%s %s'):format(info.firstname or '', info.lastname or ''):gsub('^%s+', ''):gsub('%s+$', '')
            end
        end
    end
    return GetPlayerName(src) or ('Player %s'):format(src)
end

function Arena.Framework.GetIdentifier(src)
    local player = Arena.Framework.GetPlayer(src)
    local fw = Arena.Framework.name
    if player then
        if fw == 'esx' then
            return player.identifier
        elseif fw == 'qb' or fw == 'qbx' then
            return player.PlayerData and player.PlayerData.citizenid
        end
    end
    if fw == 'ox' then
        local ok, playerId = pcall(function()
            return exports.ox_core:GetPlayer(src).charId
        end)
        if ok and playerId then return tostring(playerId) end
    end
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and id:find('license:') then return id end
    end
    return tostring(src)
end

function Arena.Framework.GetMoney(src, account)
    local player = Arena.Framework.GetPlayer(src)
    if not player then return 0 end
    local fw = Arena.Framework.name
    account = account or (Config.Rewards and Config.Rewards.account) or 'cash'
    if fw == 'esx' then
        if account == 'bank' then
            local acc = player.getAccount and player.getAccount('bank')
            return acc and acc.money or 0
        end
        return player.getMoney and player.getMoney() or 0
    elseif fw == 'qb' or fw == 'qbx' then
        local money = player.PlayerData and player.PlayerData.money
        local atype = account == 'bank' and 'bank' or 'cash'
        return money and money[atype] or 0
    end
    return 0
end

function Arena.Framework.RemoveMoney(src, amount, account)
    if not amount or amount <= 0 then return false end
    if Arena.Framework.GetMoney(src, account) < amount then return false end
    local player = Arena.Framework.GetPlayer(src)
    if not player then return false end
    local fw = Arena.Framework.name
    account = account or (Config.Rewards and Config.Rewards.account) or 'cash'
    if fw == 'esx' then
        if account == 'bank' then
            player.removeAccountMoney('bank', amount)
        else
            player.removeMoney(amount)
        end
        return true
    elseif fw == 'qb' or fw == 'qbx' then
        local atype = account == 'bank' and 'bank' or 'cash'
        player.Functions.RemoveMoney(atype, amount, 'arena-bet')
        return true
    end
    return false
end

function Arena.Framework.AddMoney(src, amount, account)
    if not amount or amount <= 0 then return end
    local player = Arena.Framework.GetPlayer(src)
    if not player then return end
    local fw = Arena.Framework.name
    account = account or (Config.Rewards and Config.Rewards.account) or 'cash'

    if fw == 'esx' then
        if account == 'bank' then
            player.addAccountMoney('bank', amount)
        elseif account == 'black_money' then
            player.addAccountMoney('black_money', amount)
        else
            player.addMoney(amount)
        end
    elseif fw == 'qb' or fw == 'qbx' then
        local atype = account == 'bank' and 'bank' or 'cash'
        player.Functions.AddMoney(atype, amount, 'arena-reward')
    end
end

function Arena.Framework.HasItem(src, item, count)
    count = count or 1
    if GetResourceState('ox_inventory') == 'started' then
        return (exports.ox_inventory:Search(src, 'count', item) or 0) >= count
    end
    return true
end
