Config = {}

-- Departments you want to support/show in menus
Config.Departments = {
    { label = 'Police',     value = 'police' },
    { label = 'FENZ',       value = 'fenz'   },
    { label = 'Ambulance',  value = 'cas'    },
    { label = 'Tow',        value = 'tow'    },
}

-- Chat tag colors
Config.ChatColors = {
    duty    = { r = 0,   g = 165, b = 255 },
    comms   = { r = 255, g = 200, b = 0   },
    call111 = { r = 255, g = 50,  b = 50  },
    info    = { r = 200, g = 200, b = 200 },
}

-- Optional COMMS whitelist (license: identifiers). Empty = anyone.
Config.CommsWhitelist = {
    -- 'license:87f78c5b32c47c7ff94eb66d2f68b2da7872b7d8',
}

-- Tiny beep when menus open
Config.EnableMenuDing = true

-- Chat prefix
Config.Prefix = '^3^7 '

-- Blip settings for 111 calls (tweak sprites/colors to taste)
-- Common sprites: 56 (police car), 60 (hospital), 436 (fire), 68 (tow), 161 (default alert)
Config.Blips = {
    police  = { sprite = 56,  color = 29, scale = 1.0, durationMS = 180000 },
    fenz    = { sprite = 436, color = 1,  scale = 1.0, durationMS = 180000 },
    cas     = { sprite = 60,  color = 2,  scale = 1.0, durationMS = 180000 },
    tow     = { sprite = 68,  color = 5,  scale = 1.0, durationMS = 180000 },
    default = { sprite = 161, color = 0,  scale = 1.0, durationMS = 180000 },
    setRoute = true  -- also place a GPS waypoint for recipients
}
