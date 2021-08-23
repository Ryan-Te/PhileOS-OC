--Terminal API for PhileOS-OC
local gpu = component.proxy(components.gpu)
gpu.setDepth(1)
gpu.setResolution(50, 16)
gpu.fill(1, 1, 50, 16, " ")

local cpX = 1
local cpY = 1

local term = {}

term.getBgColour = function()
    return gpu.getBackground()
end

term.getTxColour = function()
    return gpu.getForeground()
end

term.setBgColour = function(col)
    gpu.setBackground(col)
end

term.setTxColour = function(col)
    gpu.setForeground(col)
end

term.invertColours = function()
    local bg = gpu.getBackground()
    gpu.setBackground(gpu.getForeground())
    gpu.setForeground(bg)
end

term.write = function(string)
    gpu.set(cpX, cpY, string)
    cpX = cpX + #string
end

term.read = function()
    local text = ""
    cursor = 1
    local ic = false
    local id = phileos.addTimer(0.5)
    while true do
        gpu.set(cpX, cpY, text.." ")
        if ic then term.invertColours() end
        if cursor > #text then
            gpu.set(cpX + cursor - 1, cpY, " ")
        else
            gpu.set(cpX + cursor - 1, cpY, text:sub(cursor, cursor))
        end
        if ic then term.invertColours() end
        local e = table.pack(phileos.waitForEvent())
        if e[1] == "char" then
            text = text:sub(1, cursor - 1)..e[2]..text:sub(cursor)
            cursor = cursor + 1
        elseif e[1] == "key" then
            if e[2] == keys.left and cursor > 1 then
                cursor = cursor - 1
            elseif e[2] == keys.right and cursor <= #text then
                cursor = cursor + 1
            elseif e[2] == keys.backspace and cursor > 1 then
                text = text:sub(1, cursor - 2)..text:sub(cursor)
                gpu.set(cpX + #text + 1, cpY, " ")
                cursor = cursor - 1
            elseif e[2] == keys.enter then
                gpu.set(cpX, cpY, text.." ")
                break
            end
        elseif e[1] == "timer" and e[2] == id then
            ic = not ic
            id = phileos.addTimer(0.5)
        end
    end
    cpX = 1
    cpY = cpY + 1
    local Sx, Sy = gpu.getResolution()
    if cpY > Sy then
        local lines = cpY - Sy
        gpu.copy(1, lines, Sx, Sy, 0, 0 - lines)
        gpu.fill(1, Sy, Sx, Sy, " ")
        cpY = Sy
    end
    return text
end

term.print = function(str)
    local Sx = gpu.getResolution()
    while str ~= "" do
        gpu.set(cpX, cpY, str)
        cpX = 1
        cpY = cpY + 1
        local Sx, Sy = gpu.getResolution()
        if cpY > Sy then
            local lines = cpY - Sy
            gpu.copy(1, lines, Sx, Sy, 0, 0 - lines)
            gpu.fill(1, Sy, Sx, Sy, " ")
            cpY = Sy
        end
        str = string.sub(str, Sx - cpX + 2)
    end
end

term.setCursorPos = function(x, y)
    cpX = x
    cpY = y
end

term.getSize = function()
    return gpu.getResolution()
end

term.maxSize = function()
    return gpu.maxResolution()
end

term.setSize = function(x, y)
    return gpu.setResolution(x, y)
end

term.getDepth = function()
    return gpu.getDepth()
end

term.maxDepth = function()
    return gpu.maxDepth()
end

term.setDepth = function(depth)
    return gpu.setDepth(depth)
end


term.clear = function()
    local Sx, Sy = gpu.getResolution()
    gpu.fill(1, 1, Sx, Sy, " ")
end

return term