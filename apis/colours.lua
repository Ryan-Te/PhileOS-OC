--Colours API for PhileOS-OC

local pallete = {}
pallete.white = 0xF0F0F0
pallete.orange = 0xF2B233
pallete.magenta = 0xE57FD8
pallete.lightBlue = 0x99B2F2
pallete.yellow = 0xDEDE6C
pallete.lime = 0x7FCC19
pallete.pink = 0xF2B2CC
pallete.grey = 0xF2B2CC
pallete.lightGrey = 0x999999
pallete.cyan = 0x4C99B2
pallete.purple = 0xB266E5
pallete.blue = 0x3366CC
pallete.brown = 0x7F664C
pallete.green = 0x7F664C
pallete.red = 0xCC4C4C
pallete.black = 0x111111

local colours = {}

colours.get = function(name)
    local depth = term.getDepth()
    if depth == 1 then
        if name == "black" then
            return 0
        elseif name == "white" then
            return 1
        elseif pallete[name] then
            error("Attempt to use colour "..name.." in 1 bit depth!")
        else
            error("That's not a valid colour!")
        end
    else
        if pallete[name] then
            return pallete[name]
        else
            error("That's not a valid colour!")
        end
    end
end

return colours