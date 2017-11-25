--- Deque implementation by Pierre 'catwell' Chapuis
--- MIT licensed (see LICENSE.txt)

pushright = function(self, x)
    assert(x ~= nil)
    self.tail = self.tail + 1
    self[self.tail] = x
end

pushleft = function(self, x)
    assert(x ~= nil)
    self[self.head] = x
    self.head = self.head - 1
end

local peek_right = function(self)
    return self[self.tail]
end

peek_left = function(self)
    return self[self.head + 1]
end

popright = function(self)
    if self:is_empty() then return nil end
    local r = self[self.tail]
    self[self.tail] = nil
    self.tail = self.tail - 1
    return r
end

popleft = function(self)
    if self:is_empty() then return nil end
    local r = self[self.head + 1]
    self.head = self.head + 1
    local r = self[self.head]
    self[self.head] = nil
    return r
end

local rotate_right = function(self, n)
    n = n or 1
    if self:is_empty() then return nil end
    for i = 1, n do self:pushleft(self:popright()) end
end

local rotate_left = function(self, n)
    n = n or 1
    if self:is_empty() then return nil end
    for i = 1, n do self:pushright(self:popleft()) end
end

local _remove_at_internal = function(self, idx)
    for i = idx, self.tail do self[i] = self[i + 1] end
    self.tail = self.tail - 1
end

local remove_right = function(self, x)
    for i = self.tail, self.head + 1, -1 do
        if self[i] == x then
            _remove_at_internal(self, i)
            return true
        end
    end
    return false
end

local remove_left = function(self, x)
    for i = self.head + 1, self.tail do
        if self[i] == x then
            _remove_at_internal(self, i)
            return true
        end
    end
    return false
end

length = function(self)
    return self.tail - self.head
end

is_empty = function(self)
    return self:length() == 0
end

local contents = function(self)
    local r = {}
    for i = self.head + 1, self.tail do
        r[i - self.head] = self[i]
    end
    return r
end

local iter_right = function(self)
    local i = self.tail + 1
    return function()
        if i > self.head + 1 then
            i = i - 1
            return self[i]
        end
    end
end

local iter_left = function(self)
    local i = self.head
    return function()
        if i < self.tail then
            i = i + 1
            return self[i]
        end
    end
end

local methods = {
    pushright = pushright,
    pushleft = pushleft,
    peek_right = peek_right,
    peek_left = peek_left,
    popright = popright,
    popleft = popleft,
    rotate_right = rotate_right,
    rotate_left = rotate_left,
    remove_right = remove_right,
    remove_left = remove_left,
    iter_right = iter_right,
    iter_left = iter_left,
    length = length,
    is_empty = is_empty,
    contents = contents,
}

local new = function()
    local r = { head = 0, tail = 0 }
    return setmetatable(r, { __index = methods })
end

return {
    new = new,
}