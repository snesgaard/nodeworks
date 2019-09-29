local function edge_traversal(self, from_key, edge_key, to_key, ...)
    local states = rawget(self, "__states")
    local edges = rawget(self, "__edges")
    local data = rawget(self, "__data")
    local from = states[from_key] or {}
    local to = states[to_key] or {}

    rawset(self, "__state", from_key)
    log.debug("Leaving %s", from_key)
    if from.exit and from.exit(self, data, ...) then
        rawset(self, "__pending", false)
        return
    end

    log.debug("Traversing %s %s", from_key, to_key)
    local f = from[edge_key]
    if  f and f(self, data, ...) then
        rawset(self, "__pending", false)
        return
    end

    rawset(self, "__pending", false)
    rawset(self, "__state", to_key)
    log.debug("Entering %s", to_key)
    if to.enter then
        to.enter(self, data, ...)
    end
end

local function data_method(self)
    return rawget(self, "__data")
end

local fsm = {}

function fsm:method_closure(f)
    local data = rawget(self, "__data")
    return function(this, ...)
        return f(this, data, ...)
    end
end

function fsm:__index(key)
    local edges = rawget(self, "__edges") or {}
    local states = rawget(self, "__state_methods") or {}
    local methods = rawget(self, "__global_methods") or {}
    local state_key = rawget(self, "__state") or ""

    local edge = edges[state_key] or {}
    local state = states[state_key] or {}
    local method = methods[state_key] or {}

    if edge[key] then
        return edge[key]
    end
    if state[key] then
        return state[key]
    end
    if methods[key] then
        return methods[key]
    end

    local val = rawget(self, key)

    if val then return val end

    local m = getmetatable(fsm)
    if m then
        return m[key]
    end
end

function fsm:create(data)
    local edges = dict()
    local state_methods = dict()
    local global_methods = dict()

    rawset(self, "__edges", edges)
    rawset(self, "__data", dict())
    rawset(self, "__states", data.states)
    rawset(self, "__methods", data.methods)
    rawset(self, "__state", "")
    rawset(self, "__state_methods", state_methods)
    rawset(self, "__global_methods", global_methods)

    -- Create state method clores
    for name, state in pairs(data.states) do
        local s = dict()
        for key, func in pairs(state) do
            s[key] = fsm.method_closure(self, func)
        end
        state_methods[name] = s
    end

    -- Create global method closures
    for name, func in pairs(data.methods) do
        global_methods[name] = fsm.method_closure(self, func)
    end

    global_methods.data = data_method
    -- Create edge closures
    for _, edge in ipairs(data.edges) do
        local e = edges[edge.from] or dict()
        e[edge.name] = function(self, ...)
            local co = coroutine.create(edge_traversal)
            local status, msg = coroutine.resume(
                co, self, edge.from, edge.name, edge.to, ...
            )
            if not status then error(msg) end
        end
        edges[edge.from] = e
    end

    if data.init then fsm.force(self, data.init) end
end

function fsm:force(to)
    local co = coroutine.create(edge_traversal)
    local from = rawget(self, "__state")
    return coroutine.resume(co, self, from, "", to)
end

return fsm
