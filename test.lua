local aeternum = require "./aeternum/init"
local socket = require "socket"

local loop = aeternum.Loop:new()


local f = loop:runUntilComplete(coroutine.create(function()
    print("fump")
    local fut = aeternum.Future:new()
    print("new future", fut)
    local sock = socket.connect("localhost", 6667)--socket.connect("irc.freenode.net", 6667)
    if sock == nil then
        error("Failed to connect!")
    end
    local a = sock:receive(52)
    print("received", a)
    local function reader()
        print("reading")
        fut:setResult(sock:receive(64))
        loop:removeReader(sock)
        print("removed reader")
    end

    print("creating reader")
    loop:createReader(sock, reader)
    print("created success")



    inspect = require("inspect")
    print("getting final result")
    --local result = fut:wait()


    local result = fut:result()
    print("got result", inspect(result))
    sock:close()
    print("socket closed")
    return result
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