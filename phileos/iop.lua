term.setSize(term.maxSize())
term.clear()
term.setCursorPos(1, 1)
--computer.pullSignal()
while true do
    local e = table.pack(phileos.waitForEvent(nil, true))
    e.n = nil
    if e[1] ~= nil then
        for i, v in pairs(e) do
            term.write(tostring(v))
            term.write(" ")
        end
        term.print(" ");
    end
end