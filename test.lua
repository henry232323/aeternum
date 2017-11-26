local aetherum = require "aetherum"
local socket = require "socket"

local loop = aetherum.Loop:new()


local f = loop:runUntilComplete(coroutine.create(function()
    print("fump")
    local fut = aetherum.Future:new()
    local sock = socket.connect("localhost", 6667)--socket.connect("irc.freenode.net", 6667)
    if sock == nil then
        error("Failed to connect!")
    end
    local a = sock:receive(52)
    print(a)
    local function reader()
        print("arfed")
        fut:setResult(sock:receive(64))
        loop:removeReader(sock)
    end

    print("bumpkin")
    loop:createReader(sock, reader)
    print("doki doki loki boki")
    while not fut.complete and fut._error == nil do
            print("how much waiting")
            coroutine.yield()
            print(f)
    end
    local result = future:result()
    --local result = fut:wait()
    print(532123, result, "else resultate")
    sock:close()
    return "clap clapa"
end))
inspect = require "inspect"
print(f, inspect(f))

a = [[
loop:runUntilComplete(coroutine.create(function()
    print("yeld")
    local f = coroutine.yield("sleep", 3)
    print(f, 123)
    print("frikc")
    local j = coroutine.yield("FUN")
    print(j, "do re me")
end))
]]