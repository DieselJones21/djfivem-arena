--[[
    Donator coins used by the arena shop.
    Wire this to your Envy Donator Store in open_sv.lua, or set Config.Donator.resource exports.
]]

Arena = Arena or {}
Arena.Donator = {}

local function cfg()
    return Config.Donator or {}
end

local function exportCall(resource, method, ...)
    if not resource or resource == '' or not method or method == '' then return nil, false end
    if GetResourceState(resource) ~= 'started' then return nil, false end
    local ok, result = pcall(function(...)
        return exports[resource][method](exports[resource], ...)
    end, ...)
    if ok then return result, true end
    return nil, false
end

function Arena.Donator.Label()
    return cfg().label or 'Coins'
end

function Arena.Donator.GetBalance(src)
    if GetDonatorBalance then
        local n = GetDonatorBalance(src)
        if type(n) == 'number' then return n end
    end
    local c = cfg()
    local val, hit = exportCall(c.resource, c.getBalance, src)
    if hit and type(val) == 'number' then return val end
    if c.item and GetResourceState('ox_inventory') == 'started' then
        local ok, count = pcall(function()
            return exports.ox_inventory:GetItemCount(src, c.item) or 0
        end)
        if ok then return count end
    end
    return 0
end

function Arena.Donator.Remove(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return true end
    if RemoveDonatorCurrency then
        local ok = RemoveDonatorCurrency(src, amount)
        if ok ~= nil then return ok == true end
    end
    local c = cfg()
    local val, hit = exportCall(c.resource, c.remove, src, amount)
    if hit then return val ~= false end
    if c.item and GetResourceState('ox_inventory') == 'started' then
        local have = Arena.Donator.GetBalance(src)
        if have < amount then return false end
        local ok, removed = pcall(function()
            return exports.ox_inventory:RemoveItem(src, c.item, amount)
        end)
        return ok and removed ~= false
    end
    return false
end
