local function ding()
    if not Config.EnableMenuDing then return end
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

local function getPlayerLocation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local s1, s2 = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street1 = GetStreetNameFromHashKey(s1)
    local street2 = GetStreetNameFromHashKey(s2)
    local street = street1 or ''
    if street2 and street2 ~= '' then
        street = (street ~= '' and (street .. ' / ' .. street2)) or street2
    end
    return { x = coords.x + 0.0, y = coords.y + 0.0, z = coords.z + 0.0, street = street }
end

local function createCallBlip(payload)
    if not payload or not payload.coords or not payload.coords.x then return end
    local d = payload.dept or 'default'
    local cfg = (Config.Blips and (Config.Blips[d] or Config.Blips.default)) or { sprite = 161, color = 0, scale = 1.0, durationMS = 180000 }

    local blip = AddBlipForCoord(payload.coords.x + 0.0, payload.coords.y + 0.0, payload.coords.z + 0.0)
    SetBlipSprite(blip, cfg.sprite or 161)
    SetBlipColour(blip, cfg.color or 0)
    SetBlipScale(blip, cfg.scale or 1.0)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('111 #%d'):format(payload.callId or 0))
    EndTextCommandSetBlipName(blip)

    if Config.Blips and Config.Blips.setRoute then
        SetNewWaypoint(payload.coords.x + 0.0, payload.coords.y + 0.0)
    end

    CreateThread(function()
        Wait((cfg.durationMS or 180000) | 0)
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end)
end

CreateThread(function()
    Wait(1500)
    TriggerServerEvent('services:playerLoaded')
end)

RegisterCommand('duty', function()
    ding()
    local opts = {}
    for _, d in ipairs(Config.Departments) do
        opts[#opts+1] = { label = d.label, value = d.value }
    end
    table.insert(opts, 1, { label = 'Civilian (Off Duty)', value = 'civ' })

    local input = lib.inputDialog('Go On Duty', {
        { type = 'select', label = 'Department', options = opts, default = 'civ', required = true },
        { type = 'input',  label = 'Callsign (e.g., HQA1, CHQ2, AMB12)', placeholder = 'CIV if off duty', required = false }
    })

    if not input then return end
    local dept, callsign = input[1], input[2]
    TriggerServerEvent('services:setDuty', dept, callsign)
end, false)

RegisterCommand('111', function()
    ding()
    local input = lib.inputDialog('111 Call', {
        { type = 'checkbox', label = 'Police'    },
        { type = 'checkbox', label = 'FENZ'      },
        { type = 'checkbox', label = 'Ambulance' },
        { type = 'checkbox', label = 'Tow'       },
        { type = 'textarea', label = 'Job Details', required = true, placeholder = 'Describe the incident / location / plate / injuries...' },
    })

    if not input then return end

    local depts = {}
    if input[1] then depts[#depts+1] = 'police' end
    if input[2] then depts[#depts+1] = 'fenz'   end
    if input[3] then depts[#depts+1] = 'cas'    end
    if input[4] then depts[#depts+1] = 'tow'    end
    local details = input[5]

    local loc = getPlayerLocation()
    TriggerServerEvent('services:create111Call', depts, details, loc)
end, false)

RegisterCommand('comms', function()
    ding()
    local opts = {}
    for _, d in ipairs(Config.Departments) do
        opts[#opts+1] = { label = d.label, value = d.value }
    end

    local ctxId = 'comms_menu'
    lib.registerContext({
        id = ctxId,
        title = 'COMMS Console',
        options = {
            {
                title = 'Register as COMMS',
                description = 'Receive all calls for a department',
                icon = 'headset',
                onSelect = function()
                    local pick = lib.inputDialog('Register COMMS', {
                        { type = 'select', label = 'Department', options = opts, required = true }
                    })
                    if pick then
                        TriggerServerEvent('services:setComms', pick[1], true)
                    end
                end
            },
            {
                title = 'Unregister COMMS',
                description = 'Stop receiving calls',
                icon = 'ban',
                onSelect = function()
                    TriggerServerEvent('services:setComms', nil, false)
                end
            }
        }
    })
    lib.showContext(ctxId)
end, false)

-- Sideways /services with COMMS per department
RegisterCommand('services', function()
    lib.callback('services:getServicesCount', false, function(c)
        if not c then return end
        local cp = (c.comms and c.comms.police) or 0
        local cf = (c.comms and c.comms.fenz)   or 0
        local cc = (c.comms and c.comms.cas)    or 0
        local ct = (c.comms and c.comms.tow)    or 0
        local commsText = ('Police: %d, FENZ: %d, CAS: %d, Tow: %d'):format(cp, cf, cc, ct)
        local msg = ('Services — Police: %d | FENZ: %d | CAS: %d | Tow: %d | COMMS (%s) | Civ: %d')
            :format(c.police or 0, c.fenz or 0, c.cas or 0, c.tow or 0, commsText, c.civ or 0)
        TriggerEvent('chat:addMessage', {
            color = { 0, 150, 255 },
            multiline = false,
            args = { '', (Config.Prefix or '') .. msg }
        })
    end)
end, false)

RegisterNetEvent('services:receive111Call', function(payload)
    createCallBlip(payload)
end)
