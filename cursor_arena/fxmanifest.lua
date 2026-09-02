fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cursor_arena'
author 'DJ FiveM'
description 'PvP arenas — FFA, 1v1–4v4, TDM. Qbox / ox / interact / illenium-appearance.'
version '2.3.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/weapons.lua',
    'config/maps.lua',
    'config/lobbies.lua',
    'shared/*.lua',
    'locales/*.lua',
}

client_scripts {
    'client/00_state.lua',
    'client/open_cl.lua',
    'client/ambulance.lua',
    'client/combat.lua',
    'client/spectate.lua',
    'client/arena.lua',
    'client/ui.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/discord.lua',
    'server/open_sv.lua',
    'server/framework.lua',
    'server/inventory.lua',
    'server/ambulance.lua',
    'server/voice.lua',
    'server/discord.lua',
    'server/stats.lua',
    'server/match.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/assets/*',
}

dependencies {
    'ox_lib',
}

provides {
    'cursor_arena',
}
