--Get the components
local components = {}
for k, v in component.list() do
    if components[v] == nil then
        components[v] = k
    end
end

for k, v in component.list("filesystem") do
    if component.invoke(k, "exists", "/apis/phileos.lua") then
        components.filesystem = k
        break
    end
end

--Check for components
if not components.gpu then
    error("No GPU! (even though you can't see this)")
elseif not components.filesystem then
    error("No Filesystem! (how did you even install this OS?)")
elseif not components.keyboard then
    error("No Keyboard! (how else are you going to use this OS?)")
end


--Get the fs API
local filesystem = component.proxy(components.filesystem)

if not filesystem.exists("/apis/fs.lua") then
    error("Crititcal API missing: fs (reinstall the OS)")
end
local fh = filesystem.open("/apis/fs.lua")
local contents = ""
local filepart = filesystem.read(fh, 2048)
while filepart ~= nil do
    contents = contents..filepart
    filepart = filesystem.read(fh, 2048)
end
filesystem.close(fh)
local func = load(contents)
local fs = func(components)

for k, _ in component.list("filesystem") do
    local len = 3
    while true do
        local ok = pcall(fs.mount, k:sub(1, len), "/mnt/"..k:sub(1, len).."/")
        if ok then break end
        len = len + 1
    end
end
ok, err = fs.run("/boot/loader.lua")
if not ok then
    error("Error with bootloader: "..err)
end