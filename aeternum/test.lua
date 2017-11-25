Loop = require("loop")
Future = require("futures").Future
socket = require("socket")

loop = Loop:new()


loop:runUntilComplete(coroutine.create( function()
    print("fump")
    local fut = Future:new()
    local sock = socket.connect("irc.freenode.net", 6667)
    local a = sock:receive(52)
    print(a)
    local function reader()
        print("arsed")
        fut.set_result(sock:receive(64))
    end

    print("bumpkin")
    loop:createReader(sock, reader)

    local result = fut.wait()
    print(result)
    socket.close()

end))

loop:runUntilComplete(coroutine.create(function()
    print("yeld")
    local f = coroutine.yield("sleep", 3)
    print(f, 123)
    print("frikc")
    local j = coroutine.yield("FUN")
    print(j, "do re me")
end))
