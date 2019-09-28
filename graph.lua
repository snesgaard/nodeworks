local function wrap_function(f)
    local node = {}

    function node:begin(...)
        local args = {...}
        for i, v in ipairs(args) do
            self[i] = v
        end
    end

    function node:enter()
        f(unpack(self))
    end

    return node
end

local graph = {}
graph.__index = graph

function graph.create()
    local this = {
        _nodes = {},
        _edge = {},
        _parent = {},
        _data = {},
        _last_node = nil
    }
    return setmetatable(this, graph)
end


function graph:leaf(id, nodetype, ...)
    local it = type(id)
    if it == "table" or it == "function" then
        return self:leaf(#self._nodes + 1, id, nodetype, ...)
    end

    local nt = type(nodetype)
    local is_table = nt == "table"
    local is_func = nt == "function"

    if not is_table and not is_func then
        error("Invalid nodetype: " .. nt)
    end

    nodetype = is_table and nodetype or wrap_function(nodetype)

    if self._nodes[id] then
        error("ID Conflict! " .. id)
    end
    self._nodes[id] = nodetype
    self._data[id] = dict()

    if nodetype.begin then
        nodetype.begin(self._data[id], ...)
    end

    if self._last_node then
        self:make_edge(self._last_node, id)
        --local edge = self:edge(self._last_node)
        --edge[#edge + 1] = id
    end

    if not self._root then
        self:root(id)
    end
    return self, id
end


function graph:branch(...)
    local _, id = self:leaf(...)
    self._last_node = id
    return self, id
end


function graph:edge(id)
    local l = self._edge[id]
    if not l then
        l = list()
        self._edge[id] = l
    end
    return l
end


function graph:make_edge(from, to)
    local edge = self._edge[from] or list()
    edge[#edge + 1] = to
    self._parent[to] = from
    self._edge[from] = edge
    return self
end


function graph:find(id)
    return self._nodes[id]
end


function graph:data(...)
    return self._data[join(...)]
end


function graph:parent(id)
    return self._parent[id]
end


function graph:sort(id, f)
    self._edge[id] = self:edge(id):sort(f)
    return self
end


function graph:root(id)
    self._root = id
    return self
end


function graph:free(id)
    self._nodes[id] = nil
    self._data[id] = nil
    self._edge[id] = nil
    self._parent[id] = nil
    return self
end


function graph:sever(to, do_purge)
    do_purge = do_purge or true
    local from = self._parent[to]
    if not from then
        log.warn("not connected... " .. to)
        return
    end
    local edge = self:edge(from)
    local index = edge:argfind(to)
    if not index then
        local msg = string.format(
            "connected but no index <%s> <%s>", tostring(to), tostring(from)
        )
        error(msg)
    end

    self._edge[from] = edge:erase(index)

    if not do_purge then return end

    local function purge(id)
        local edge = self:edge(id)
        self:free(id)
        if self._root == id then
            self._root = from
        end
        for _, id in ipairs(edge) do purge(id) end
    end

    purge(to)
    return self
end


function graph:bind(from, to)
    local edge = self:edge(from)
    if edge:argfind(to) then return end
    edge[#edge + 1] = to
    return self
end


function graph:traverse(id)
    if not id and not self._root then
        --error("Either root must be defined or an id given")
        return
    end

    local function get_memory(node)
        return node.memory and {node.memory(data)} or {}
    end


    id = id or self._root
    local function inner_traverse(id)
        local nodetype = self._nodes[id] or {}
        local data = self._data[id] or {}
        local memory = get_memory(nodetype)

        if nodetype.enter then
            nodetype.enter(data)
        end

        for _, other in ipairs(self:edge(id)) do
            inner_traverse(other)
        end
        if nodetype.exit then
            nodetype.exit(data, unpack(memory))
        end
    end

    inner_traverse(id)

    return self
end

function graph:reset(id, ...)
    local data = self._data[id]
    local node = self._nodes[id]
    if not node then return end
    if node.begin then
        node.begin(data, ...)
    end
end

function graph:back(id)
    if not self._nodes[id] then
        error("Node not defined: " .. id)
    end
    self._last_node = id
    return self
end

function graph:map(f, ...)
    f(self, ...)
    return self
end

return graph
