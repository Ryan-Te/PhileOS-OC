--PhileOS-OC Default Commands

local cmds = {}

cmds.help = function()
    local help = {
        "PhileOS-OC Default Commands ([] = aliases) ",
        "                                           ",
        "help : display this list                   ",
        "dir  : list directory                 [ls] ",
        "cd   : change directory                    ",
        "clear: clear the screen                    ",
        "mkdir: make directory                      ",
        "del  : delete file / directory        [rm] ",
        "ren  : rename file / directory             ",
        "copy : copy file / directory     (WIP)[cp] ",
        "run  : run a program                       ",
        "batch: run a batch file                    ",
        "load : load more Commands from a file (WIP)",
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
        return "Not a directory"
    end
end
cmds.ls = cmds.dir

cmds.cd = function(dir)
    dir = fs.canoncialPath(dir, true)
    if fs.exists(dir) then
        if fs.isDir(dir) then
            phileos.workingDir = dir
        else
            return "That isn't a directory!"
        end
    else
        return "That directory doesn't exist!"
    end
end

cmds.clear = function()
    term.clear()
    term.setCursorPos(1, 1)
end

cmds.mkdir = function(dir)
    dir = fs.canoncialPath(dir, true)
    if fs.exists(dir) then
        return "File or directory already exists there!"
    end
    fs.makeDir(dir)
end

cmds.del = function(path)
    path = fs.canoncialPath(path, true)
    if path == "/" then
        return "Don't delete the entire drive!"
    end
    if not fs.exists(path) then
        return "That file doesn't exist!"
    end
    fs.delete(path)
end
cmds.rm = cmds.del
cmds.ren = function(path, newName)
    path = fs.canoncialPath(path, true)
    newName = fs.canoncialPath(newName, true)
    if not fs.exists(path) then
        return "That file doesn't exist!"
    end
    if fs.exists(newName) then
        return "New name already exists!"
    end
    fs.ren(path, newName)
end


cmds.run = function(file)
    if not string.find(file, "%.") then
        file = file..".lua"
    end
    file = fs.canoncialPath(file, true)
    if fs.exists(file) then
        if not fs.isDir(file) then
            term.clear()
            term.setCursorPos(1, 1)
            local ok, err = pcall(function() fs.run(file) end)
            term.clear()
            term.setCursorPos(1, 1)
            if not ok then
                return "Error: "..err
            end
        else
            return "You can't run a directory!"
        end
    else
        return "Program doesn't exist!"
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
                        return "Error at line "..i..": "..ret
                    end
                else
                    return "Error at line "..i..": Bad command"
                end
            end
        else
            return "You can't run a directory!"
        end
    else
        return "Batch file doesn't exist!"
    end
end

return cmds