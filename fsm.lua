local function do_edge_traversal(self, from, edge, to, ...)
    local is_loop = from == to

    local function exit(...)
        if not from or is_loop then return end
        local f = self._exit[from]
        if not f then return end
        return f(self, ...)
     end

    local function enter(...)
        if not to or is_loop then return end
        local f = self._enter[to]
        if not f then return end
        return f(self, ...)
    end

    local function transit(...)
        if not from or not edge then return end
        local key = string.join(edge, name)
        local f = self._transits[key]
        if not f then return end
        return f(self, ...)
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

    self._pending = false
    self._state = to
    enter(...)
end

local fsm = {}
fsm.__index = fsm

function fsm.create(args)
    local this = {
        _data = args.data
        _enters = dict(),
        _exits = dict(),
        _edges = dict(),
        _transits = dict(),
        _state = nil,
        _pending = nil
    }

    for key, val in ipairs(args.data or {}) do
        this[key] = this[key] or val
    end

    for name, state in pairs(args.states) do
        this._enters[name] = state.enter
        this._exits[name] = state.exit
    end

    for _, edge in ipairs(args.edges) do
        local key = string.join(edge.name, edge.from)
        this._edges[key] = edge.to or edge.from
        this._transits[key] = edge.action or identity

        fsm[edge.name] = fsm[edge.name] or function(self, ...)
            return self:invoke(name, ...)
        end
    end

    return setmetatable(this, fsm)
end

function fsm:invoke(name, ...)
    if not self._pending then
        log.warn("Cannot transition while pending")
        return
    end
    if not self._state then
        log.warn("Cannot transition if not in a state")
        return
    end

    local from = self._state
    local edge = name
    local to = this._edges[string.join(edge, from)]
    if not to then
        log.warn(string.format("Edge %s not defined fro %s", from, edge))
    end

    self._transition_co = coroutine.create(do_edge_traversal)
    coroutine.resume(self._transition_co, self, from, edge, to, ...)
end

function fsm:goto(name, ...)
    if self._transition_co then
        event:clear(self._transition_co)
        self._pending = false
    end

    local from = self._state
    local edge = nil
    local to = name
    self._transition_co = coroutine.create(do_edge_traversal)
    coroutine.resume(self._transition_co, self, from, edge, to, ...)
end

return fsm
