local function traverse_table(table, key, ...)
    if not key then return table end

    if not table[key] then
        local w = {}
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

function server:clear(co)
    local path = self._co_registry[co]
    if not path then return end

    self._co_registry[co] = nil

    local w = get_subtable(
        self._waiters,
        type(path) == "table" and unpack(path) or path
    )
    local index = w[co]
    if not index then return end
    w[index] = nil
    w[co] = nil
end

function server:close(a, b)
    local function do_clear(table, i, co)
        self._co_registry[co] = nil
        table[i] = nil
        table[co] = nil
    end

    local w = get_subtable(self._waiters, a, b)
    -- If we arrived in a final subtable via path or table key combo
    -- Then we simply clear all entries in that table
    if type(a) == "string" or (a and b) then
        local size = #w
        for i = 1, size do
            do_clear(w, i, w[i])
        end
    -- Else we assume that an object was provided and we wan to close all
    -- Subtables associated with it
    elseif a then
        for key, _ in pairs(w) do
            self:close(a, key)
        end
    end
end

local function __invoke_listener(args, f, ...)
    f(args, ...)
end

function server:spin()
    while #self._queue > 0 do
        self:spin_once()
    end
end

function server:spin_once()
    local waiter_table = self._waiters

    local function invoke_msg(...)
        local args = {get_args(...)}
        local listeners = get_subtable(self._waiters, ...)
        -- Clear waiter table
        --waiter_table[path] = {}
        local size = #listeners
        for i = 1, size do
            local co = listeners[i]
            -- This can be made more efficient
            if type(co) == "thread" then
                listeners[i] = nil
                listeners[co] = nil
                self._co_registry[co] = nil
                coroutine.resume(co, unpack(args))
            elseif type(co) == "table" then
                __invoke_listener(args, unpack(co))
            end
        end
    end

    local queue = self._queue
    self._queue = {}
    for _, msg in ipairs(queue) do
        invoke_msg(unpack(msg))
    end
end

function server:listen(...)
    local path = {get_path(...)}
    local args = {get_args(...)}
    if #args <= 0 then
        log.warn("Callback must be defined")
        return
    end
    local w = get_subtable(self._waiters, ...)
    local index = #w + 1
    w[args] = index
    w[index] = args
    self._co_registry[args] = path
    return args
end

function server:wait(...)
    local path = get_path(...)
    local co = get_args(...)
    co = co or coroutine.running()
    if not co then
        log.warn("Cannot wait in main coroutine")
        return
    end
    local w = get_subtable(self._waiters, ...)
    local index = #w + 1
    w[co] = index
    w[index] = co
    self._co_registry[co] = path
    return coroutine.yield()
end

function server:invoke(...)
    self._queue[#self._queue + 1] = {...}
end

return function()
    local this = {
        _queue = {},
        _waiters = {},
        _co_registry = {}
    }
    return setmetatable(this, server)
end
