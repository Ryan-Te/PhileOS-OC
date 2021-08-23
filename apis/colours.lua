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
    if pallete[name] then
        if depth == 1 then
            local brightness = 0
            local colour = pallete[name]
            for i = 1, 3 do
                brightness = brightness + (colour % 256)
                colour = colour - (colour % 256)
                colour = colour / 256
            end
            if brightness < 383 then
                return 0
            else
                return 1
            end
        end
        return pallete[name]
    else
        error("That's not a valid colour!")
    end
end

return colours