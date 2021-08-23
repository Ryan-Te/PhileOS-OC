--PhileOS API for PhileOS-OC
local phileos = {}

local modKeys = {
    LShift = false,
    LCrtl = false,
    LAlt = false,
    RAlt = false,
    RCrtl = false,
    RShift = false,
    Shift = false,
    Crtl = false,
    Alt = false,
} 

local timers = {}

phileos.version = "0.0.1 PRE ALPHA"

phileos.workingDir = "/"

phileos.tokenize = function(str, split)
    local ret = {}
    for v in string.gmatch(str, ".-"..split) do
        table.insert(ret, v:sub(1, -2))
        str = str:sub(#v + 1)
    end
    table.insert(ret, str)
    return ret
end

phileos.addTimer = function(time)
    local id = #timers + 1
    timers[id] = computer.uptime() + time
    computer.pushSignal("timer", id)
    return id
end

phileos.sleep = function(time)
    local id = phileos.addTimer(time)
    while true do
        e, idtc = phileos.waitForEvent()
        if e == "timer" and idtc == id then return end
    end
end

phileos.waitForEvent = function(time, raw)
    while true do
        local e = table.pack(computer.pullSignal())
        if e == nil then return nil end
        if e[1] == "key_down" then
            if modKeys.LCrtl and modKeys.LAlt and e[4] == keys.c then computer.pushSignal("terminate") end
            if e[3] >= 32 then
                return "char", string.char(e[3])
            end
            if e[4] == 42 then modKeys.LShift = true end
            if e[4] == 29 then modKeys.LCrtl = true end
            if e[4] == 56 then modKeys.LAlt = true end
            if e[4] == 184 then modKeys.RAlt = true end
            if e[4] == 157 then modKeys.RCrtl = true end
            if e[4] == 54 then modKeys.RShift = true end
            modKeys.Shift = modKeys.LShift or modKeys.RShift
            modKeys.Crtl = modKeys.LCrtl or modKeys.RCrtl
            modKeys.Alt = modKeys.LAlt or modKeys.RAlt
            if not raw then return "key", e[4] end
        elseif e[1] == "key_up" then
            if e[3] >= 32 then
                return "char_up", string.char(e[3])
            end
            if e[4] == 42 then modKeys.LShift = false end
            if e[4] == 29 then modKeys.LCrtl = false end
            if e[4] == 56 then modKeys.LAlt = false end
            if e[4] == 184 then modKeys.RAlt = false end
            if e[4] == 157 then modKeys.RCrtl = false end
            if e[4] == 54 then modKeys.RShift = false end
            modKeys.Shift = modKeys.LShift or modKeys.RShift
            modKeys.Crtl = modKeys.LCrtl or modKeys.RCrtl
            modKeys.Alt = modKeys.LAlt or modKeys.RAlt
            if not raw then return "key_up", e[4] end
        elseif e[1] == "touch" then
            if not raw then return "mouse_click", e[3], e[4], e[5] end
        elseif e[1] == "drag" then
            if not raw then return "mouse_drag", e[3], e[4], e[5] end
        elseif e[1] == "drop" then
            if not raw then return "mouse_up", e[3], e[4], e[5] end
        elseif e[1] == "scroll" then
            if not raw then return "mouse_scroll", e[3], e[4], e[5] end
        elseif e[1] == "clipboard" then
            if not raw then return "paste", e[3] end
        elseif e[1] == "timer" then
            if timers[e[2]] <= computer.uptime() then
                return "timer", e[2]
            else
                computer.pushSignal("timer", e[2])
                goto continue
            end
        elseif e[1] == "terminate" then
            error("terminated")
        elseif e[1] == "component_added" then
            if e[3] == "filesystem" then
                local len = 3
                while true do
                    local ok = pcall(fs.mount, e[2]:sub(1, len), "/mnt/"..e[2]:sub(1, len).."/")
                    if ok then break end
                    len = len + 1
                end
            end
        elseif e[1] == "component_removed" then
            if e[3] == "filesystem" then
                local path = fs.getMountPoint(e[2])
                fs.unmount(path)
            end
        else
            if not raw then return "native", table.unpack(e) end
        end
        if raw and e[1] ~= timer then return table.unpack(e) end
        ::continue::
    end
end

phileos.getModKey = function(key)
    return modKeys[key]
end

return phileos