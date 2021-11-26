--PhileOS Login Program

--TODO: Make this lol

phileos.sleep(10)
thread.sendPacket(1, "Hello, World!");
while true do
    coroutine.yield()
end