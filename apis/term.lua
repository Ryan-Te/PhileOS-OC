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
    local ocpX = cpX
    cursor = 1
    local Sx, Sy = gpu.getResolution()
    local ic = false
    local id = phileos.addTimer(0.5)
    while true do
        if cpY + math.floor((cursor - 2 + ocpX) / Sx) > Sy then
            local lines = cpY + math.floor((cursor - 2 + ocpX) / Sx) - Sy
            gpu.copy(1, lines, Sx, Sy, 0, 0 - lines)
            gpu.fill(1, Sy, Sx, Sy, " ")
            cpY = Sy - lines
        end
        term.print(text.." ", true)
        if ic then term.invertColours() end
        if cursor > #text then
            gpu.set(((cpX + cursor - 2) % Sx) + 1, cpY + math.floor((cursor - 2 + ocpX) / Sx), " ")
        else
            gpu.set(((cpX + cursor - 2) % Sx) + 1, cpY + math.floor((cursor - 2 + ocpX) / Sx), text:sub(cursor, cursor))
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
                gpu.set(((cpX + #text) % Sx) + 1, cpY + math.floor((#text + ocpX) / Sx), " ")
                cursor = cursor - 1
            elseif e[2] == keys.enter then
                term.print(text.." ", true)
                break
            end
        elseif e[1] == "timer" and e[2] == id then
            ic = not ic
            id = phileos.addTimer(0.5)
        end
    end
    cpX = 1
    cpY = cpY + 1 + math.floor((#text - 2 + ocpX) / Sx)
    if cpY > Sy then
        local lines = cpY - Sy
        gpu.copy(1, lines, Sx, Sy, 0, 0 - lines)
        gpu.fill(1, Sy, Sx, Sy, " ")
        cpY = Sy
    end
    return text
end

term.print = function(str, nomove)
    local Sx, Sy = gpu.getResolution()
    local yp = cpY
    local xp = cpX
    while str ~= "" do
        gpu.set(xp, yp, str)
        yp = yp + 1
        if not nomove then
            cpX = 1
            cpY = cpY + 1
            if cpY > Sy then
                local lines = cpY - Sy
                gpu.copy(1, lines, Sx, Sy, 0, 0 - lines)
                gpu.fill(1, Sy, Sx, Sy, " ")
                cpY = Sy
            end
        end
        str = string.sub(str, Sx - xp + 2)
        xp = 1
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