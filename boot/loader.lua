--PhileOS-OC boot loader
if not fs.exists("/apis/term.lua") then
    error("Crititcal API missing: term (reinstall the OS)")
end
if not fs.exists("/apis/phileos.lua") then
    error("Crititcal API missing: phileos (reinstall the OS)")
end

fs.require("term")
fs.require("phileos")

local Sx, Sy = term.getSize()

term.invertColours()
term.print("PhileOS-OC "..phileos.version..(" "):rep(Sx - #phileos.version - 11))
term.invertColours()

local apis = fs.list("/apis/")
term.print("Loaded API: fs (1 / "..#apis..")")
term.print("Loaded API: term (2 / "..#apis..")")
term.print("Loaded API: phileos (3 / "..#apis..")")
local loaded = 3

for _, v in pairs(apis) do
    if type(v) == "string" then
        if v:sub(-4) == ".lua" then
            local api = v:sub(1, -5)
            if api ~= "fs" and api ~= "term" and api ~= "phileos" then
                local ok, err = pcall(function() fs.require(api) end)
                if ok then
                    loaded = loaded + 1
                    term.print("Loaded API: "..api.." ("..loaded.." / "..#apis..")")
                else
                    term.print("Couldnt load API: "..api..": "..err)
                end
            end
        end
    end
end

if not fs.exists("/phileos/shell.lua") then
    error("Crititcal File missing: shell (reinstall the OS)")
end

fs.run("/phileos/shell.lua")