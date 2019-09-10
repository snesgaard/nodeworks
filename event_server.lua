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

function server:spin(state, history)
    history = history or list()
    while #self._queue > 0 do
        history, state = self:spin_once(state, history)
    end
    -- Histories should be combined and returned after this
    return history, state
end

function server:update(dt)
    return self:_invoke_msg(history, nil, "update", dt)
end

function server:_invoke_msg(history, state, ...)
    local args = {get_args(state, ...)}
    local listeners = get_subtable(self._waiters, ...)
    history = history or list()
    -- Clear waiter table
    --waiter_table[path] = {}
    local size = #listeners
    for i = 1, size do
        local co = listeners[i]
        -- This can be made more efficient
        local function invocation()
            if type(co) == "thread" then
                listeners[i] = nil
                listeners[co] = nil
                self._co_registry[co] = nil
                -- TODO Add a state and info variable to this
                -- Such that internal state is mutated after each callback
                -- Potentially
                -- Like the current epoch strcture in the state handling
                -- This way, state can be changed in an ordered manner
                -- E.g
                -- id, next_state, info = coroutine.resume(co, unpack(args))
                -- Then broadcast a /state/<id> event
                -- Thus we can have async events in an ordered manner
                --
                -- Something similar for visuals ystem, would be cool,
                -- but probably infesiable with nodes and coroutines
                if state then
                    return coroutine.resume(co, state, unpack(args))
                else
                    return coroutine.resume(co, unpack(args))
                end
            elseif type(co) == "table" then
                if state then
                    return true, __invoke_listener(state, args, unpack(co))
                else
                    return true, __invoke_listener(args, unpack(co))
                end
            end
        end
        local status, epoch = invocation()

        history[#history + 1] = epoch

        local function next_state()
            if not epoch then return state end
            return epoch.state or state
        end

        state = next_state()
    end
    --Thus return an ordered history list of state transitions
    return history, state
end

function server:spin_once(state, history)
    local waiter_table = self._waiters

    local queue = self._queue
    self._queue = {}
    history = history or list()
    for _, msg in ipairs(queue) do
        history, state = self:_invoke_msg(history, state, unpack(msg))

    end
    return history, state
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

function server:sleep(time)
    while time > 0 do
        local dt = self:wait("update")
        time = time - dt
    end
end

function server:__call(a, ...)
    if a == nil then
        log.warn("Nill invocation, maybe old code")
        return
    end
    return self:invoke(a, ...)
end

function server:invoke(...)
    self._queue[#self._queue + 1] = {...}
end

function server:instant_invoke(...)
    return self:_invoke_msg(...)
end

return function()
    local this = {
        _queue = {},
        _waiters = {},
        _co_registry = {}
    }
    return setmetatable(this, server)
end
