--FS api for PhileOS-OC
local args = {...}
local filesystem = component.proxy(args[1].filesystem)

local fs = {}

local loaded = {fs = fs, components = args[1]}

fs.packagePath = "/apis/?.lua;?.lua"

fs.exists = function(path)
    return filesystem.exists(path)
end

fs.list = function(path)
    return filesystem.list(path)
end

fs.makeDir = function(path)
    return filesystem.makeDirectory(path)
end

fs.isDir = function(path)
    return filesystem.isDirectory(path)
end

fs.delete = function(path)
    return filesystem.remove(path)
end

fs.ren = function(path1, path2)
    return filesystem.rename(path1, path2)
end

fs.read = function(path)
    local fh = filesystem.open(path)
    local contents = ""
    local filepart = filesystem.read(fh, 2048)
    while filepart ~= nil do
        contents = contents..filepart
        filepart = filesystem.read(fh, 2048)
    end
    filesystem.close(fh)
    return contents
end

fs.write = function(path, data)
    local fh = filesystem.open(path, "w")
    filesystem.write(fh, data)
    filesystem.close(fh)
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
        if filesystem.exists(testFile) then
            file = testFile
            break
        end
    end
    if file == nil then
        error("Module doesn't exist!")
    end
    local fh = filesystem.open(file)
    local contents = ""
    local filepart = filesystem.read(fh, 2048)
    while filepart ~= nil do
        contents = contents..filepart
        filepart = filesystem.read(fh, 2048)
    end
    filesystem.close(fh)
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
    local fh = filesystem.open(file)
    local contents = ""
    local filepart = filesystem.read(fh, 2048)
    while filepart ~= nil do
        contents = contents..filepart
        filepart = filesystem.read(fh, 2048)
    end
    filesystem.close(fh)

    local env = setmetatable(loaded, {__index = _ENV})
    local func = load(contents, nil, nil, env)
    local returns = table.pack(pcall(func, ...))
    if returns[1] then
        table.remove(returns, 1)
        return table.unpack(returns)
    else
        error("Error running file:"..returns[2])
    end
end

return fs