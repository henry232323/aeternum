Loop = require "loop"
Deque = require "deque"
futures = require "futures"
Future = futures.Future
Task = futures.Task

function spawn(coro)
    return coroutine.yield("createTask", coro)
end

function sleep(time)
    return coroutine.yield("sleep", time)
end

function createReader(socket, callback)
    return coroutine.yield("createReader", socket, callback)
end

function createWriter(socket, callback)
    return coroutine.yield("createWriter", socket, callback)
end

function removeReader(socket)
    return coroutine.yield("removeReader", socket)
end

function removeWriter(socket)
    return coroutine.yield("removeWriter", socket)
end

function getLoopTime()
    return coroutine.yield("time")
end


return {
    spawn = spawn,
    sleep = sleep,
    createReader = createReader,
    createWriter = createWriter,
    removeReader = removeReader,
    removeWriter = removeWriter,
    getLoopTime = getLoopTime,
    Loop = Loop,
    Deque = Deque,
    Future = Future,
    Task = Task
}
