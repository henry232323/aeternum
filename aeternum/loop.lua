local Deque = require "deque"
local futures = require "futures"
local heap = require "binary_heap" -- or "skew_heap"
local socket = require "socket"
local inspect = require "inspect"

local Task = futures.Task

local Loop = {}


function table.keys(self)
    local set = {}
    local n = 0

    for k, _ in pairs(self) do
        n = n + 1
        set[n] = k
    end
    return set
end

function table.empty(self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function Loop:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.tasks = Deque.new()
    self.queue = Deque.new()
    self.timers = heap:new()
    self.readers = {}
    self.writers = {}
    self._read_calls = {}
    self._write_calls = {}

    return o
end

function Loop:createTask(coro)
    local task = Task:new(coro)
    self.tasks:pushright(task)
    return task
end

function Loop:time()
    return os.clock()
end

function Loop:runUntilComplete(coro)
    local task = Task:new(coro)
    self.queue:pushleft(task)
    local run = self.runOnce
    repeat until not run(self) and task.complete or task._error
    return task:result()
end

function Loop:runForever()
    local run = self.runOnce
    while true do run(self) end
end

function Loop:sleep(time)
    socket.sleep(time)
end

function Loop:tablelength(T)
    local count = 0
    for _ in pairs(T) do count = count + 1 end
    return count
end

function Loop:runOnce()
    for _ = 1, self.tasks:length() do
        local popped = self.tasks:popleft()
        self.queue:pushright(popped)
    end
    while not self.timers:empty() do
        local task, time = unpack(self.timers:pop())
        if not task.cancelled and not task.complete then
            if time < self:time() then
                self.tasks:pushright(task)
            else
                self.timers:insert({ task, time })
                break
            end
        end
    end

    self:poll()


    while not self.queue:is_empty() do
        local task = self.queue:popleft()
        if not task.cancelled and not task.complete then
            if task._data == nil then
                task._data = {}
            end
            local result = { task:resume(task._data) }
            local response = table.remove(result, 1)
            local command
            if not response then
                if #result == 1 and result[1] == "cannot resume dead coroutine" then
                    task:setResult(unpack(task._data))
                else
                    task:setException(result[1])
                end
            else
                task._data = result
                if #result ~= 0 then -- These are all our 'commands' that can be yielded directly into the loop
                    command = table.remove(task._data, 1) -- Always {'command', unpack(args)} after the initial response
                    if command == 'sleep' then
                        self.timers:insert({ task, self:time() + task._data[1] }) -- Add our time to our list of timers
                    else
                        if command == "loop" then -- If we want the loop, give it to em
                            task._data = self
                        else
                            if command == "current_task" then
                                task._data = task
                            else
                                local attr = self[command]
                                if attr then
                                    task._data = attr(self, unpack(task._data))
                                    if type(task._data) == "thread" and command ~= "create_task" then
                                        self:createTask(task._data)
                                    else
                                        if type(task._data) == "function" and command ~= "create_task" then
                                            self:createTask(coroutine.create(task._data))
                                        end
                                    end
                                    self.tasks:pushright(task)
                                end
                                print("zizizizizizi")
                            end
                        end
                    end
                end
                if command ~= 'sleep' then
                    if task._data._coro_type == "Future" then
                        self.tasks:pushright(task._data)
                    else
                        if type(task._data) == "thread" then
                            self:createTask(task._data)
                        end
                    end
                    print("requeuing")
                    self.tasks:pushright(task)
                end
            end
        end
    end
    return not self.timers:empty() or not self.tasks:is_empty() or not self.queue:is_empty() or not table.empty(self.readers) or not table.empty(self.writers)
end

function Loop:poll()
    if table.empty(self.readers) and table.empty(self.writers) then
        if self.queue:is_empty() and self.tasks:is_empty() and not self.timers:empty() then
            local task, time = unpack(self.timers:pop())
            self:sleep(time)
            self.tasks:pushright(task)
        end
    else
        local timeout = 0
        if self.queue:is_empty() and self.tasks:is_empty() and not self.timers:empty() then
            local task, time = unpack(self.timers:pop())
            timeout = time
        end
        local readready, writeready, _ = socket.select(table.keys(self.readers), table.keys(self.writers), timeout)

        for _, sock in ipairs(readready) do
            local val = self.readers[sock]
            if self._read_calls[sock] == nil then
                self._read_calls[sock] = true
                local task = self:createTask(coroutine.create(val))
                task:setCallback(self._readCallback, { self, sock })
            end
        end

        for _, sock in ipairs(writeready) do
            local val = self.writers[sock]
            if self._write_calls[sock] == nil then
                self._write_calls[sock] = true
                local task = self:createTask(coroutine.create(val))
                task:setCallback(self._writeCallback, { self, sock })
            end
        end
    end
end

function Loop:_readCallback(sock)
    self._read_calls[sock] = nil
end

function Loop:_writeCallback(sock)
    self._write_calls[sock] = nil
end


function Loop:createReader(socket, callback)
    self.readers[socket] = callback
end

function Loop:createWriter(socket, callback)
    self.writers[socket] = callback
end

function Loop:removeReader(socket)
    self.readers[socket] = nil
end

function Loop:removeWriter(socket)
    self.writers[socket] = nil
end


return Loop