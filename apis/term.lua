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

term.createWin = function(x, y, w, h)
    local win = {x, y, colours.get("black"), colours.get("white")}
    for i = 1, w do
        table.insert(win, {})
        for j = 1, h do
            table.insert(win[i + 4], {colours.get("black"), colours.get("black"), " "})
        end
    end
    return win
end

term.resizeWin = function(win, nw, nh)
    local newwin = {win[1], win[2], win[3], win[4]}
    for i = 1, w do
        table.insert(win, {})
        for j = 1, h do
            if win[i] then
                table.insert(win[i + 4], {win[i][j][1] or colours.get("black"), win[i][j][2] or colours.get("black"), win[i][j][3] or " "})
            else
                table.insert(win[i + 4], {colours.get("black"), colours.get("black"), " "})
            end
        end
    end
    return newwin
end

term.toWin = function(win)
    gpu = {
        getBackground = function() return win[3] end,
        getForeground = function() return win[4] end,
        setBackground = function(col) win[3] = col end,
        setForeground = function(col) win[4] = col end,
        set = function(x, y, text)
            for i = y, y + #text - 1 do
                win[x + 4][i] = {win[3], win[4], text.sub(i, i)}
            end
        end,
        getResolution = function() return #win - 4, #win[5] end,
        setResolution = function(x, y) win = term.resizeWin(win, nw, nh) end,
        fill = function(xs, ys, xe, ye, char)
            if #char ~= 1 then error("Fill string must be length of 1!") end
            for i = xs, xe do
                for j = ys, ye do
                    if win[i + 4] then
                        win[i + 4][j] = (win[i + 4][j] and {win[3], win[4], char}) or nil
                    end
                end
            end
        end,
        copy = function(xs, ys, xe, ye, tx, ty)
            for i = xs, xe do
                for j = ys, ye do
                    if win[i + 4 + tx] then
                        win[i + 4 + tx][j + ty] = (win[i + 4 + tx][j + ty] and {win[3], win[4], char}) or nil
                    end
                end
            end
        end,
        getDepth = function() return gpu.getDepth() end,
    }
end

term.toDef = function()
    gpu = component.proxy(components.gpu)
end

term.renderWin = function(win, xO, yO)
    local number = gpu.allocateBuffer(win[3], win[4])
    gpu.setActiveBuffer(number)
    for x = 1, #win - 4 do
        for y = 1, #win[5] do
            gpu.setBackground(win[x + 4][y][1])
            gpu.setForeground(win[x + 4][y][2])
            gpu.set(x, y, win[x + 4][y][3])
        end
    end
    local XP = (xO or win[1])
    local YP = (yO or win[2])
    gpu.bitblt(0, YP, XP, win[3], win[4], number, 1, 1)
    gpu.freeBuffer(number)
end

return term