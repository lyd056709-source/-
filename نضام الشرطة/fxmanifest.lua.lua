fx_version 'cerulean'
game 'gta5'

author 'Your Name / AI Developer'
description 'An advanced police system framework for FiveM ESX'
version '1.0.0'

-- Shared Scripts (Config)
shared_scripts {
    '@es_extended/config.lua',
    'config.lua'
}

-- Client Scripts
client_scripts {
    '@es_extended/client/functions.lua',
    'client/main.lua',
    'client/ui.lua'
}

-- Server Scripts
server_scripts {
    '@es_extended/server/functions.lua',
    'server/main.lua',
    'server/events.lua'
}

-- UI (Optional, if you add NUI later)
-- ui_page 'html/index.html'
-- files {
--     'html/index.html',
--     'html/css/style.css',
--     'html/js/script.js'
-- }
