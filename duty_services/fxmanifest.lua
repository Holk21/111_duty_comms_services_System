fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'services'
author 'Braiden Marshall'
version '1.0.0'
description 'Standalone duty / comms / 111 / services using ox_lib'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    'server.lua'
}

dependencies {
    'ox_lib'
}
