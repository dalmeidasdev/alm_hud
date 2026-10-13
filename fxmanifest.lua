fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Almeida Scripts'
description 'HUD completo: status, dinheiro, emprego, voz, arma e painel do veículo'
version '1.0.0'

-- Sem `dependencies` de framework: a ponte (bridge/) descobre sozinha o que está no servidor.

shared_scripts {
    'config.lua',
    'shared/locale.lua',
    'locales/*.lua',
    'bridge/shared.lua',
}

client_scripts {
    'bridge/client/*.lua',
    'client/main.lua',
}

server_scripts {
    'server/version.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

-- O que o comprador pode abrir e editar. Todo o resto em Lua vai criptografado pelo Asset Escrow.
escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'bridge/*.lua',
    'bridge/**/*.lua',
}
