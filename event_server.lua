local function get_subtable(path, waiter_table)
    if not waiter_table[path] then
        local w = {}
        waiter_table[path] = w
        return w
    else
        return waiter_table[path]
    end
end

local server = {}
server.__index = server

function server:clear(co)
    local path = _co_registry[co]
    if not path then return end
    _co_registry[co] = nil

    local w = get_subtable(path, self._waiters)
    local index = w[co]
    if not index then return end
    w[index] = nil
    w[co] = nil
end

function server:spin()
    local waiter_table = self._waiters

    local function invoke_msg(path, ...)
        local listeners = waiter_table[path] or {}
        -- Clear waiter table
        waiter_table[path] = {}
        for _, co in ipairs(listeners) do
            coroutine.resume(co, ...)
            -- TODO probably not needed
            _co_registry[co] = nil
        end
    end

    print("here we go", #self._queue)
    while #self._queue > 0 do
        local queue = self._queue
        self._queue = {}
        for _, msg in ipairs(queue) do
            invoke_msg(unpack(msg))
        end
    end
    print("again")
end

function server:wait(path, co)
    co = co or coroutine.running()
    if not co then
        log.warn("Cannot wait in main coroutine")
        return
    end
    local w = get_subtable(path, self._waiters)
    w[co] = index
    w[index] = co
    _co_registry[co] = path
    return coroutine.yield()
end

function server:invoke(path, ...)
    self._queue[#self._queue + 1] = {path, ...}
end

return function()
    local this = {
        _queue = {},
        _waiters = {},
        _co_registry = {},
    }
    return setmetatable(this, server)
end
