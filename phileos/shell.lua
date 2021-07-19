term.setSize(term.maxSize())
term.clear()
term.setCursorPos(1, 1)
term.print("PhileOS-OC Shell")
term.print("Version "..phileos.version)
if not fs.exists("/phileos/command.lua") then
    error("Crititcal File missing: commands (reinstall the OS)")
end

local cmds = fs.run("/phileos/command.lua")
if fs.exists("/autoexec.bat") then
    local ok, ret = pcall(cmds.batch, "/autoexec.bat")
    ret = ret or ""
    if ok then
        local toPrint = phileos.tokenize(ret, "\n")
        for _, v in pairs(toPrint) do
            term.print(v)
        end
    else
        term.print("Error: "..ret)
    end
end

while true do
    term.write(phileos.workingDir..">")
    local command = term.read()
    local cmdTbl = phileos.tokenize(command, " ")
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
            term.print("Error: "..ret)
        end
    else
        term.print("Bad command")
    end
end