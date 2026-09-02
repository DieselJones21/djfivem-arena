--[[
    Server-only. Do NOT add this file to fxmanifest files{} —
    the webhook URL must never reach a client.
]]

ArenaDiscord = {
    enabled = false,
    url = '',
    name = 'Arena',
    avatar = '',
    ffa = true,
    tdm = true,
    showdown = true,
}

--[[
    Discord display names in the arena UI.
    Optional bot token via convar: setr cursor_arena:discord_token "BOT_TOKEN"
    Also tries Badger_Discord_API / zdiscord exports when those resources are running.
]]
DiscordNames = {
    enabled = true,
    botToken = GetConvar('cursor_arena:discord_token', ''),
    preferGlobalName = true,
}
