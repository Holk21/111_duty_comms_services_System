    local PlayerState = {}
    local CommsByDept = { police = {}, fenz = {}, cas = {}, tow = {} }
    local NextCallId = 1000

    local function getIdentifier(src)
        for _, id in ipairs(GetPlayerIdentifiers(src)) do
            if id:find('license:') == 1 then
                return id
            end
        end
        return GetPlayerIdentifierByType and GetPlayerIdentifierByType(src, 'license') or ('src:'..src)
    end

    local function ensurePlayer(src)
        if not PlayerState[src] then
            PlayerState[src] = { dept = 'civ', callsign = 'CIV', onDuty = false, isComms = false }
        end
        return PlayerState[src]
    end

    local function sendChat(src, color, msg)
        TriggerClientEvent('chat:addMessage', src, {
            color = { color.r, color.g, color.b },
            multiline = true,
            args = { '', (Config.Prefix or '') .. msg }
        })
    end

    local function route111ToTarget(srcList, color, payload)
        for _, target in ipairs(srcList) do
            TriggerClientEvent('services:receive111Call', target, payload)
            sendChat(target, color, payload.chatText)
        end
    end

    local function broadcastDept(dept, color, msg, payload)
        local list = {}
        for _, id in ipairs(GetPlayers()) do
            local sid = tonumber(id)
            local st = ensurePlayer(sid)
            if st.onDuty and st.dept == dept then
                list[#list+1] = sid
            end
        end
        -- Mirror to COMMS
        for sid, _ in pairs(CommsByDept[dept] or {}) do
            list[#list+1] = sid
        end

        if payload then
            route111ToTarget(list, color, payload)
        else
            for _, sid in ipairs(list) do
                sendChat(sid, color, msg)
            end
        end
    end

    AddEventHandler('playerDropped', function()
        local src = source
        local st = PlayerState[src]
        if st then
            if st.isComms and CommsByDept[st.dept] then
                CommsByDept[st.dept][src] = nil
            end
            PlayerState[src] = nil
        end
    end)

    RegisterNetEvent('services:playerLoaded', function()
        local src = source
        ensurePlayer(src)
        sendChat(src, Config.ChatColors.info, 'You are ^2CIVILIAN^7 by default. Use ^2/duty^7 to go on duty.')
    end)

    RegisterNetEvent('services:setDuty', function(dept, callsign)
        local src = source
        local st = ensurePlayer(src)

        if st.isComms and CommsByDept[st.dept] then
            CommsByDept[st.dept][src] = nil
            st.isComms = false
        end

        st.dept = dept or 'civ'
        st.callsign = (callsign and callsign ~= '' and callsign) or (dept == 'civ' and 'CIV' or 'UNSET')
        st.onDuty = (dept ~= 'civ')

        if st.onDuty then
            sendChat(src, Config.ChatColors.duty, ('You are now on duty as ^2%s^7 (^5%s^7).'):format(st.dept:upper(), st.callsign))
            broadcastDept(st.dept, Config.ChatColors.duty, ('%s is now on duty (^5%s^7).'):format(GetPlayerName(src), st.callsign))
        else
            sendChat(src, Config.ChatColors.duty, 'You are ^1OFF DUTY^7 (CIV).')
        end
    end)

    RegisterNetEvent('services:setComms', function(dept, enabled)
        local src = source
        local st = ensurePlayer(src)

        if Config.CommsWhitelist and #Config.CommsWhitelist > 0 then
            local lic = getIdentifier(src)
            local ok = false
            for _, id in ipairs(Config.CommsWhitelist) do
                if id == lic then ok = true break end
            end
            if not ok then
                sendChat(src, Config.ChatColors.comms, 'You are not whitelisted for COMMS.')
                return
            end
        end

        dept = dept or st.dept or 'police'
        CommsByDept[dept] = CommsByDept[dept] or {}

        if enabled then
            st.isComms = true
            st.dept = dept
            CommsByDept[dept][src] = true
            sendChat(src, Config.ChatColors.comms, ('You are registered as ^3COMMS^7 for ^2%s^7.'):format(dept:upper()))
        else
            st.isComms = false
            if CommsByDept[dept] then CommsByDept[dept][src] = nil end
            sendChat(src, Config.ChatColors.comms, 'You are no longer registered as ^3COMMS^7.')
        end
    end)

    -- 111 call intake (multi-department) with coords + street and formatted report
    RegisterNetEvent('services:create111Call', function(targetDepts, details, loc)
        local src = source
        local callId = NextCallId
        NextCallId = NextCallId + 1

        if type(targetDepts) ~= 'table' or #targetDepts == 0 then
            sendChat(src, Config.ChatColors.call111, 'No department selected. Call cancelled.')
            return
        end
        if not details or details == '' then
            sendChat(src, Config.ChatColors.call111, 'No details provided. Call cancelled.')
            return
        end

        loc = loc or {}
        local caller = GetPlayerName(src)
        local locText = loc.street or (loc.x and (('%.1f, %.1f'):format(loc.x, loc.y))) or 'Unknown'

        -- Styled multi-line block (colors use GTA chat codes ^n)
        local summary = ([[^4------------------------------
^3New 111 Report:^7
^5[Caller Name]^7: %s
^5[Location]^7: %s
^5[Report]^7: %s
^4------------------------------]]):format(caller, locText, details)

        -- Send to each chosen department with payload for blips/waypoints
        for _, d in ipairs(targetDepts) do
            local payload = {
                callId = callId,
                dept = d,
                details = details,
                from = caller,
                coords = { x = loc.x, y = loc.y, z = loc.z },
                street = locText,
                chatText = summary
            }
            broadcastDept(d, Config.ChatColors.call111, summary, payload)
        end

        -- Confirm back to caller
        sendChat(src, Config.ChatColors.call111, ('Your 111 Call ^6#%d^7 was sent.'):format(callId))
    end)

    lib.callback.register('services:getServicesCount', function(src)
        local counts = { police = 0, fenz = 0, cas = 0, tow = 0, civ = 0 }
        for _, id in ipairs(GetPlayers()) do
            local st = ensurePlayer(tonumber(id))
            if st.onDuty then
                counts[st.dept] = (counts[st.dept] or 0) + 1
            else
                counts.civ = counts.civ + 1
            end
        end
        return counts
    end)
