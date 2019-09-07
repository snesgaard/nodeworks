local function do_edge_traversal(self, from, edge, to, ...)
    local is_loop = from == to

    local from_state = self:_get_state(from)
    local to_state = self:_get_state(to)

    local function exit(...)
        if from_state.exit and not is_loop then
            from_state.exit(self, self._data, ...)
        end
     end

    local function enter(...)
        if to_state.enter and not is_loop then
            to_state.enter(self, self._data, ...)
        end
    end

    local function transit(...)
        local f = from_state[edge]
        if f then
            f(self, self._data, ...)
        end
    end

    self._pending = true
    if exit(...) then
        self._pending = false
        return
    end

    if transit(...) then
        self._pending = false
        return
    end

    if not is_loop then
        log.debug("Entering state %s", tostring(to))
    end
    self._pending = false
    self._state = to
    return enter(...)
end

local fsm = {}
fsm.__index = fsm

function fsm.create(args)
    local this = {
        _states = dict(args.states),
        _data = dict(args.data),
        _edges = dict(),
        _state = nil,
        _pending = nil
    }

    local function add_edge(from, name, to)
        to = to or from
        local key = string.join(name, from)
        -- We dont want to override, edges takes priority
        if this._edges[key] then
            return
        end
        this._edges[key] = to

        this[name] = function(self, ...)
            self:invoke(name, ...)
        end
    end

    for _, edge in pairs(args.edges) do
        add_edge(edge.from, edge.name, edge.to)
    end

    local function add_state_method(state, name, method)
        if type(method) ~= "function" then return end
        if val == "enter" or val == "exit" then return end
        add_edge(state, name)
    end

    for state_name, state in pairs(args.states) do
        for name, method in pairs(state) do
            add_state_method(state_name, name, method)
        end
    end

    this = setmetatable(this, fsm)
    this:force(args.init)
    return this
end

function fsm:invoke(name, ...)
    if self._pending then
        log.warn("Cannot transition while pending")
        return
    end
    if not self._state then
        log.warn("Cannot transition if not in a state")
        return
    end

    local from = self._state
    local edge = name
    local to = self._edges[string.join(edge, from)]
    if not to then
        log.warn(string.format("Edge %s not defined for %s", from, edge))
        return
    end

    self._transition_co = coroutine.create(do_edge_traversal)
    local status, msg = coroutine.resume(
        self._transition_co, self, from, edge, to, ...
    )
    if not status then
        log.error(msg)
    end
end

function fsm:force(name, ...)
    if self._transition_co then
        event:clear(self._transition_co)
        self._pending = false
    end

    local from = self._state
    local edge = nil
    local to = name
    self._transition_co = coroutine.create(do_edge_traversal)
    local status, msg = coroutine.resume(
        self._transition_co, self, from, edge, to, ...
    )
    if not status then
        log.error(msg)
    end
end

function fsm:_get_state(state)
    return self._states[state] or {}
end

return fsm.create
