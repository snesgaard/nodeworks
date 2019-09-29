local function traverse_table(table, key, ...)
    if not key then return table end

    if not table[key] then
        local w = dict()
        table[key] = w
    end
    return traverse_table(table[key], ...)
end

local function get_subtable(table, a, b)
    if type(a) == "string" then
        return traverse_table(table, a)
    elseif type(a) == "table" and type(b) == "string" then
        return traverse_table(table, a, b)
    end
end

local function set_subtable(table, a, b, c)
    if type(a) == "string" then
        table[a] = b or {}
    elseif type(a) == "table" and type(b) == "string" then
        local sub =  traverse_table(table, a)
        sub[b] = c or {}
    end
end

local function get_args(a, b, ...)
    if type(a) == "string" then
        return b, ...
    else
        return ...
    end
end

local function get_path(a, b)
    if type(a) == "string" then
        return a
    else
        return a, b
    end
end

local server = {}
server.__index = server


function server.create()
    this = {
        _observers = dict(),
        _address = dict(),
        _queue = list(),
    }
    return setmetatable(this, server)
end


-- Invoke can eitehr happen in a global scope, as such it is only a string
-- Or a local scope which is table and a string
function server:invoke(...)
    self._queue[#self._queue + 1] = {...}
end


function server:spin_once()
    local queue = self._queue
    self._queue = {}
    for _, msg in ipairs(queue) do
        self:_invoke_msg(unpack(msg))
    end
end


function server:spin()
    while #self._queue > 0 do
        self:spin_once()
    end
end

function server:wait(...)
    local co = get_args(...)
    co = co or coroutine.running()
    if not co then
        error("Cannot wait in main coroutine")
    end
    if self._address[co] then
        local a = list(unpack(self._address[co]))
        error(
            "Thread has already been parked: " .. tostring(a)
        )
    end
    local path = {get_path(...)}
    local o = get_subtable(self._observers, unpack(path))
    if not o then
        log.warn("invalid path %s", tostring(list(unpack(path))))
    end
    o[#o + 1] = co
    self._address[co] = path
    return coroutine.yield()
end


function server:listen(...)
    local path = {get_path(...)}
    local f = get_args(...)
    local co = coroutine.create(function()
        while f(self:wait(unpack(path))) ~= false do end
    end)
    local status, msg = coroutine.resume(co)
    if status == false then error(msg) end
    return co
end


function server:sleep(time)
    print("sleep", time)
    while time > 0 do
        dt = self:wait("update")
        time = time - dt
    end
end


function server:clear(co)
    local path = self._address[co]
    if not path then return end
    local o = get_subtable(self._observers, unpack(path))
    self._address[co] = nil
    local index = List.argfind(o, co)
    if not index then
        error("Somehow address was defined, but could not find thread")
    end
    for i = index, #o do
        o[i] = o[i + 1]
    end
end


function server:close(obj)
    self._observers[obj] = dict()
end


local function do_invocation(co, ...)
    return coroutine.resume(co, ...)
end


function server:_invoke_msg(...)
    local args = {get_args(...)}
    local o = get_subtable(self._observers, get_path(...))
    set_subtable(self._observers, get_path(...))

    -- Run through the thing
    for _, co in pairs(o) do
        self._address[co] = nil
        local status, msg = do_invocation(co, unpack(args))
        if status == false then
            error(msg)
        end
    end
end


function server:__call(...)
    return self:invoke(...)
end


function server:update(dt)
    self:_invoke_msg("update", dt)
end

return server.create
