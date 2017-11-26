Future = {
    _coro_type = "Future",
    _data = nil,
    _result = nil,
    _error = nil,
    complete = false,
    cancelled = false,
    _running = false,
    _callback = nil,
    _callback_args = nil
}

function Future:new(o)
    o = o or {}
    setmetatable(o, self)
    self._coro_type = "Future"
    self.__index = self
    self._task = coroutine.create(self.wait)

    return o
end

function Future:done()
    return self.complete
end

function Future:running()
    return self._running
end

function Future:wait()
    while not self.complete and self._error == nil do
        print("how much waiting")
        coroutine.yield()
        print(f)
    end
    print("done waiting")
    return self.result()
end

function Future:result()
    if self._error ~= nil then
        error(self._error)
    end
    if not self.complete then
        error("Result isn't ready!")
    end

    return self._result
end

function Future:setResult(data)
    inspect = require("inspect")
    print("setResult", inspect(data), self._error, self.complete)
    if self.complete or self._error ~= nil then
        error("Future already completed")
    end
    self.complete = true
    self._result = data
    if self._callback then
        self._callback(unpack(self._callback_args))
    end
end

function Future:setCallback(func, args)
    self._callback = func
    self._callback_args = args
end


function Future:setException(exception)
    if self.complete or self._error ~= nil then
        error("Future already completed")
    end
    self._error = exception
end

function Future:cancel()
    if self.cancelled then
        return true
    end
    if self.complete then
        return false
    end
    if self.running() then
        return false
    end
    self.cancelled = true
    self.setException(CancelledError)
    return true
end

function Future:resume(value)
    if type(self._task) == "thread" then
        return coroutine.resume(self._task, unpack(value))
    end

    return self._task:resume(value)
end

function Future:status()
    if type(self._task) == "thread" then
        return coroutine.status(self._task)
    end

    return self._task:status()
end

Task = Future:new()

function Task:new(coro)
    self.__index = Future
    self._task = coro
    return self
end

return {
    Task = Task,
    Future = Future
}