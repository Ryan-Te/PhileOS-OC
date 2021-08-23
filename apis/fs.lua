--FS api for PhileOS-OC
local args = {...}
local filesystem = component.proxy(args[1].filesystem)
local locations = {[args[1].filesystem] = "/"}
local filesystems = {["/"] = filesystem}

local function getMountAndPath(path)
    local mount = nil
    for i, _ in pairs(filesystems) do
        if path:sub(1, #i) == i then
            if (not mount) or (#i > #mount) then
                mount = i
            end
        end
    end
    if mount == nil then error("Not in any filesystem") end
    return mount, path:sub(#mount + 1)
end

local fs = {}

local loaded = {fs = fs, components = args[1]}

fs.packagePath = "/apis/?.lua;/?.lua"

fs.mount = function(uuid, path)
    local mountid = nil
    for k, v in component.list("filesystem") do
        if k:sub(1, #uuid) == uuid then
            if mountid then
                error("Multiple filesystem ids that start with that!")
            else
                mountid = k
            end
        end
    end
    if mountid == nil then error("Can't find that filesystem!") end
    filesystems[path] = component.proxy(mountid)
    locations[mountid] = path
end

fs.unmount = function(path)
    if filesystems[path] then
        for k, v in pairs(locations) do
            if v == path  then
                locations[k] = nil
                filesystems[path] = nil
                return true
            end
        end
    end
    error("That path is not a mount point!")
end

fs.getMountPoint = function(uuid)
    if locations[uuid] then
        return locations[uuid]
    end
    error("That filesystem doesn't exist or is not mounted!")
end

fs.exists = function(path)
    local mountInPath = false
    for i, _ in pairs(filesystems) do
        if i:sub(1, #path) == path then
            mountInPath = true
        end
    end
    local mount, path = getMountAndPath(path)
    return (filesystems[mount].exists(path) or mountInPath)
end

fs.list = function(path)
    local oldpath = path
    local mount, path = getMountAndPath(path)
    local ret = filesystems[mount].list(path) or {}
    for i, _ in pairs(filesystems) do
        if i:sub(1, #oldpath) == oldpath then
            local folder = i:sub(#oldpath + 1)
            folder = folder:sub(1, string.find(folder, "/"))
            local insert = true
            for i, v in pairs(ret) do
                if folder == v then insert = false end
            end
            if insert then table.insert(ret, folder) end
        end
    end
    return ret
end

fs.makeDir = function(path)
    local mount, path = getMountAndPath(path)
    return filesystems[mount].makeDirectory(path)
end

fs.isDir = function(path)
    local mountInPath = false
    for i, _ in pairs(filesystems) do
        if i:sub(1, #path) == path then
            mountInPath = true
        end
    end
    local mount, path = getMountAndPath(path)
    return (filesystems[mount].isDirectory(path) or mountInPath)
end

fs.delete = function(path)
    local mount, path = getMountAndPath(path)
    return filesystems[mount].remove(path)
end

fs.ren = function(path1, path2)
    local mount1, path1 = getMountAndPath(path1)
    local mount2, path2 = getMountAndPath(path2)
    if mount1 == mount2 then
        filesystems[mount1].rename(path1, path2)
    else
        local contents = fs.read(mount1..path1)
        filesystems[mount1].remove(path1)
        fs.save(mount2..path2, contents)
    end
end

fs.read = function(path)
    local mount, path = getMountAndPath(path)
    local fh = filesystems[mount].open(path)
    local contents = ""
    local filepart = filesystems[mount].read(fh, 2048)
    while filepart ~= nil do
        contents = contents..filepart
        filepart = filesystems[mount].read(fh, 2048)
    end
    filesystems[mount].close(fh)
    return contents
end

fs.write = function(path, data)
    local mount, path = getMountAndPath(path)
    local fh = filesystems[mount].open(path, "w")
    filesystems[mount].write(fh, data)
    filesystems[mount].close(fh)
end
fs.canoncialPath = function(path, addWD)
    path = path or ""
    if path:sub(1, 1) ~= "/" and addWD then
        path = loaded.phileos.workingDir..path
    end
    path = path:sub(2)
    local pathTbl = loaded.phileos.tokenize(path, "/")
    local i = 1
    while i <= #pathTbl do
        if pathTbl[i] == ".." then
            if i ~= 1 then
                table.remove(pathTbl, i - 1)
                table.remove(pathTbl, i - 1)
                i = i - 2
            else
                table.remove(pathTbl, i)
                i = i - 1
            end
        end
        i = i + 1
    end
    local path = "/"
    for i, v in pairs(pathTbl) do
        path = path..v.."/"
    end
    while string.find(path, "//") do
        local ds = string.find(path, "//")
        path = path:sub(1, ds)..path:sub(ds + 2)
    end
    return path
end

fs.require = function(module, ...)
    local file = nil
    for v in string.gmatch(fs.packagePath, ".-;") do
        local testFile = string.gsub(string.sub(v, 1, -2), "?", module)
        local ok, mount, testFile = pcall(function() return getMountAndPath(testFile) end)
        if ok then
            if filesystems[mount].exists(testFile) then
                file = mount..testFile
                break
            end
        end
    end
    if file == nil then
        error("Module doesn't exist!")
    end
    local mount, file = getMountAndPath(file)
    local fh = filesystems[mount].open(file)
    local contents = ""
    local filepart = filesystems[mount].read(fh, 2048)
    while filepart ~= nil do
        contents = contents..filepart
        filepart = filesystems[mount].read(fh, 2048)
    end
    filesystems[mount].close(fh)
    local env = setmetatable(loaded, {__index = _ENV})
    local func = load(contents, nil, nil, env)
    local returns = table.pack(pcall(func, ...))
    if returns[1] then
        table.remove(returns, 1)
        loaded[module] = returns[1]
        return table.unpack(returns)
    else
        error("Error loading module:"..returns[2])
    end
end

fs.run = function(file, ...)
    local mount, file = getMountAndPath(file)
    local fh = filesystems[mount].open(file)
    local contents = ""
    local filepart = filesystems[mount].read(fh, 2048)
    while filepart ~= nil do
        contents = contents..filepart
        filepart = filesystems[mount].read(fh, 2048)
    end
    filesystems[mount].close(fh)

    local env = setmetatable(loaded, {__index = _ENV})
    local func = load(contents, nil, nil, env)
    local returns = table.pack(pcall(func, ...))
    return table.unpack(returns)
end

return fs