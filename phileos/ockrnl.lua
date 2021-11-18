--PhileOS-OC Kernel

local function lines(str)
   local more = true
   local ret = {}
   while more do
        local nl = str:find("\n")
        if nl == nil then more = false nl = #str + 1 end
        table.insert(ret, str:sub(1, nl - 1))
        str = str:sub(nl + 1)
    end
    return ret
end

threads = {}
threadParents = {}
threadLvls = {}
threadPackets = {}
local sysfiles = lines(fs.read("/phileos/sysfiles"))

local function canAccess(isEdit, file, lvl)
    file = fs.canoncialPath(file)
    local isSysFile = false
    for i, v in pairs(sysfiles) do
        if file:sub(1, #v) == v then isSysFile = true end
    end

    if lvl == 1 and file:sub(1, 12 + #phileos.user) ~= "/user/"..phileos.user.."/home/" then return false end
    if lvl == 2 and isEdit and file:sub(1, 7 + #phileos.user) ~= "/user/"..phileos.user.."/" then return false end
    if lvl == 2 and isSysFile then return false end
    if lvl == 3 and isEdit and isSysFile then return false end
    return true
end

local function addThread(id, parent, level, program, ...)
    if level ~= 1 and level ~= 2 and level ~= 3 and level ~= 4 and level ~= 5 then error("Invalid thread level: "..level.."") end
    if parent ~= 0 then
        if level > threadLvls[parent] or level <= 1 then error("Insufficient permissions to create level "..level.." thread") end
    end
    local id = id or #threads + 1
    local _ENV2 = {table.unpack(_ENV)}
    _ENV2.gpu = (id == 1 and gpu) or nil
    threads[id] = coroutine.create(function(program, ...) 
        local env = setmetatable({
            fs = {
                mount = function(uuid, path) if level < 4 then error("Insufficient permissions to mount") fs.mount(uuid, path) end end,
                unmount = function(path) if level < 4 then error("Insufficient permissions to unmount") fs.unmount(path) end end,
                getMountPoint = function(uuid) if level < 4 then error("Insufficient permissions to get mount points") fs.getMountPoint(uuid) end end,
                exists = function(path) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.exists(path) end end,
                list = function(path) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.list(path) end end,
                makeDir = function(path) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.makeDir(path) end end,
                isDir = function(path) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.exists(isDir) end end,
                ren = function(path, path2) if not canAccess(path) then error("Insufficient permissions to access "..path) end if not canAccess(path2) then error("Insufficient permissions to access "..path2) fs.ren(path, path2) end end,
                read = function(path) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.read(path) end end,
                write = function(path) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.write(path) end end,
                canoncialPath = function(path, addWD) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.canoncialPath(path, addWD) end end,
                requireGlobal = function(module, ...) if level < 4 then error("Insufficient permissions to global require") fs.requireGlobal(module, ...) end end,
                run = function(path, ...) if not canAccess(path) then error("Insufficient permissions to access "..path) fs.run(path, ...) end end,
            },
            thread = {
                create = function(level, program, ...) addThread(nil, id, level, program, ...) end,
                delete = function(idtd) if not threads[idtd] then error("That thread doesn't exist") end if (level == 1) or (level == 2 and threadParents[idtd] ~= id) or (level == 3 and threadLvls[idtd] > 3) then error("Insufficient permissions to delete thread "..idtd) end threads[idtd] = nil threadLvls[idtd] = nil threadParents[idtd] = nil threadPackets[idtd] = nil end,
                override = function(idto, level, program, ...) if not threads[idto] then error("That thread doesn't exist") end if (level < 4) then error("Insufficient permissions to override thread "..idto) end threads[idto] = nil threadLvls[idto] = nil threadParents[idto] = nil threadPackets[idto] = nil addThread(nil, id, level, program, ...) end,
                sendPacket = function(idtr, msg) table.insert(threadPackets[idtr], {"packet", id, msg}) end,
               sendEvent = (id == 1 and function(idtr, ...) table.insert(threadPackets[idtr], {...}) end) or nil,
            },
            computer = {
                pullSignal = function(time) 
                    endtime = computer.uptime() + time 
                    while threadPackets[id] == nil do 
                        if computer.uptime() >= endtime then return nil end
                        coroutine.yield()
                    end
                    local ret = threadPackets[id][1]
                    table.remove(threadPackets[id], 1)
                    return ret
                end,
                pushSignal = function(...)
                    table.insert(threadPackets[id], {...})
                end,
            },
        }, {__index = {}})
        local fn, err = load(fs.read(program), nil, env)
        coroutine.yield()
		local ok, err = pcall(fn, table.unpack({...}))
        while true do
            gpu.set(1, 1, "H")
            coroutine.yield()
        end
	end)
    coroutine.resume(threads[id], program)
    threadLvls[id] = level
    threadParents[id] = parent
    threadPackets[id] = {}
end

addThread(nil, 0, 5, "/phileos/iop.lua")

local function update(e)
    table.insert(threadPackets[1], e)
    for i, v in pairs(threads) do
        coroutine.resume(v)
        if coroutine.status(v) == "dead" then
            error("Hi")
            threads[i] = nil 
            threadLvls[i] = nil 
            threadParents[i] = nil
            threadPackets[i] = nil
        end
    end
end

while true do
    update(phileos.waitForEvent())
end