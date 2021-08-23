--PhileOS-OC Default Commands

local cmds = {}

cmds.help = function()
    local help = {
        "PhileOS-OC Default Commands ([] = aliases)  ",
        "                                            ",
        "help : display this list                    ",
        "dir  : list directory                  [ls] ",
        "cd   : change directory                     ",
        "clear: clear the screen                [cls]",
        "mkdir: make directory                       ",
        "del  : delete file / directory         [rm] ",
        "ren  : rename file / directory              ",
        "copy : copy file / directory           [cp] ",
        "run  : run a program                        ",
        "batch: run a batch file                     ",
        "load : load more Commands from a file       ",
        "off  : shutdown or reboot the computer      ",
    }
    local ret = ""
    for _, v in pairs(help) do
        ret = ret..v.."\n"
    end
    return ret
end

cmds.dir = function(dir)
    dir = fs.canoncialPath(dir, true)
    if fs.isDir(dir) then
        local ret = "Directory of "..dir.."\n \n"
        local files = fs.list(dir)
        for i, v in pairs(files) do
            if type(v) == "string" then
                ret = ret..v
                ret = ret.."\n"
            end
        end
        return ret.." \n"
    else
        return "Not a directory", colours.pallete.red
    end
end
cmds.ls = cmds.dir

cmds.cd = function(dir)
    dir = fs.canoncialPath(dir, true)
    if fs.exists(dir) then
        if fs.isDir(dir) then
            phileos.workingDir = dir
        else
            return "That isn't a directory!", colours.pallete.red
        end
    else
        return "That directory doesn't exist!", colours.pallete.red
    end
end

cmds.clear = function()
    term.clear()
    term.setCursorPos(1, 1)
end
cmds.cls = cmds.clear

cmds.mkdir = function(dir)
    dir = fs.canoncialPath(dir, true)
    if fs.exists(dir) then
        return "File or directory already exists there!", colours.pallete.red
    end
    fs.makeDir(dir)
end

cmds.del = function(path)
    path = fs.canoncialPath(path, true)
    if path == "/" then
        return "Don't delete the entire drive!", colours.pallete.red
    end
    if not fs.exists(path) then
        return "That file doesn't exist!", colours.pallete.red
    end
    fs.delete(path)
end
cmds.rm = cmds.del
cmds.ren = function(path, newName)
    path = fs.canoncialPath(path, true)
    newName = fs.canoncialPath(newName, true)
    if not fs.exists(path) then
        return "That file doesn't exist!", colours.pallete.red
    end
    if fs.exists(newName) then
        return "New name already exists!", colours.pallete.red
    end
    fs.ren(path, newName)
end

cmds.copy = function(path, copy)
    path = fs.canoncialPath(path, true)
    copy = fs.canoncialPath(copy, true)
    if not fs.exists(path) then
        return "That file doesn't exist!", colours.pallete.red
    end
    if fs.exists(copy) then
        return "Copy location already exists!", colours.pallete.red
    end
    local contents = fs.read(path)
    fs.write(copy, contents)
end
cmds.cp = cmds.copy

cmds.run = function(file)
    if not file then
        return "Error: no file inputted", colours.pallete.red
    end
    if not string.find(file, "%.") then
        file = file..".lua"
    end
    file = fs.canoncialPath(file, true)
    if fs.exists(file) then
        if not fs.isDir(file) then
            term.clear()
            term.setCursorPos(1, 1)
            local ok, ok2, err = pcall(function() return fs.run(file) end)
            term.clear()
            term.setCursorPos(1, 1)          
            if not ok then
                return ok2, colours.pallete.red
            elseif not ok2 then
                local colon = string.find(err, ":")
                err = file..err:sub(colon)
                return err, colours.pallete.red
            end
        else
            return "You can't run a directory!", colours.pallete.red
        end
    else
        return "Program doesn't exist!", colours.pallete.red
    end
end

cmds.batch = function(file)
    if not string.find(file, "%.") then
        file = file..".bat"
    end
    file = fs.canoncialPath(file, true)
    if fs.exists(file) then
        if not fs.isDir(file) then
            local contents = fs.read(file)
            local commands = phileos.tokenize(contents, "\n")
            for i, v in pairs(commands) do
                if v:sub(-1) == "\n" then v = v:sub(1, -2) end
                if v:sub(-1) == "\r" then v = v:sub(1, -2) end
                local cmdTbl = phileos.tokenize(v, " ")
                local cmd = cmdTbl[1]
                if type(cmds[cmd]) == "function" then
                    table.remove(cmdTbl, 1)
                    local ok, ret = pcall(cmds[cmd], table.unpack(cmdTbl))
                    ret = ret or ""
                    if ok then
                        local toPrint = phileos.tokenize(ret, "\n")
                        for _, v in pairs(toPrint) do
                            term.print(v)
                        end
                    else
                        return "Error at line "..i..": "..ret, colours.pallete.red
                    end
                else
                    return "Error at line "..i..": Bad command", colours.pallete.red
                end
            end
        else
            return "You can't run a directory!", colours.pallete.red
        end
    else
        return "Batch file doesn't exist!", colours.pallete.red
    end
end

cmds.load = function(file)
    if not string.find(file, "%.") then
        file = file..".lua"
    end
    file = fs.canoncialPath(file, true)
    if not fs.exists(file) then
        return "File doesn't exist!", colours.pallete.red
    end
    if fs.isDir(file) then
        return "You can't run a directory!", colours.pallete.red
    end
    local ok, ok2, newCmds = pcall(function() return fs.run(file) end)
    if ok then
        for i, v in pairs(newCmds) do
            if cmds[i] then
                return "Command conflict with: "..i, colours.pallete.red
            else
                cmds[i] = v
                term.print("loaded command: "..i)
            end
        end
    else
        return "Error: "..err, colours.pallete.red
    end
end

cmds.off = function(reboot)
    if reboot == "reboot" then
        computer.shutdown(true)
    end
    if reboot == "shutdown" then
        computer.shutdown()
    end
end

return cmds