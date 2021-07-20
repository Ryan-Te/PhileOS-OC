--Colours API for PhileOS-OC

local pallete = {}
pallete.white =     0xffffff
pallete.orange =    0xffcc33
pallete.magenta =   0xcc66cc
pallete.lightBlue = 0x6699ff
pallete.yellow =    0xffff33
pallete.lime =      0x33cc33
pallete.pink =      0xff6699
pallete.grey =      0x333333
pallete.lightGrey = 0xcccccc
pallete.cyan =      0x336699
pallete.purple =    0x9933cc
pallete.blue =      0x333399
pallete.brown =     0x663300
pallete.green =     0x336600
pallete.red =       0xff3333
pallete.black =     0x0

local colours = {}
colours.pallete = pallete

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