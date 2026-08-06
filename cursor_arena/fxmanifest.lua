fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'cursor_arena'
author 'DJ FiveM'
description 'Configurable PVP arena with FFA, TDM, and ranked team modes'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/config.lua',
    'config/maps.lua',
    'config/modes.lua',
    'config/weapons.lua',
    'shared/*.lua',
    'locales/*.lua',
}

client_scripts {
    'client/*.lua',
}

server_scripts {
    'server/*.lua',
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
    'ox_inventory',
}

provides {
    'cursor_arena',
}
