local Node = {}
Node.__index = Node

Node.draw_origin = false

function Node.create(f, ...)
    local this = {
        _children = Dictionary.create(),
        _order = List.create(),
        _threads = Dictionary.create(),
    }

    if type(f) == "table" then
        f.__index = f.__index or f
        if not getmetatable(f) then
            local t = {__index = Node}
            setmetatable(t, Node)
            setmetatable(f, t)
        end
        this = setmetatable(this, f)
        if f.create and f.create ~= Node.create then f.create(this, ...) end
        --this.draw = f.draw
    elseif type(f) == "function" then
        this = setmetatable(this, Node)
        f(this, ...)
    else
        this = setmetatable(this, Node)
    end

    return this
end

function Node:destroy()
    for co, _ in pairs(self._threads) do
        event:clear(co)
    end

    for path, child in pairs(self._children) do
        if path ~= ".." then
            child:destroy()
        end
    end

    if self.on_destroyed then
        self.on_destroyed(self)
    end

    self:orphan()
    event(self, "on_destroyed", self)
end

function Node:upsearch(attribute)
    local node = self
    while node do
        local a = node[attribute]
        if a then return a end
        node = node:find("..")
    end
end

function Node:root()
    local prev_node = self
    local node = prev_node:find("..")

    while node do
        prev_node = node
        node = prev_node:find("..")
    end

    return prev_node
end

function Node:find(path)
    local parts = string.split(path, '/')
    local node = self
    for _, p in ipairs(parts) do
        local next_node = node._children[p]
        if not next_node then return end
        node = next_node
    end
    return node
end

function Node.rootpath(node)
    local nodes = list()

    while node do
        nodes[#nodes + 1] = node
        node = node:find("..")
    end

    return nodes:reverse()
end

function Node:hide()
    self._hidden = true
    return self
end

function Node:show()
    self._hidden = false
    return self
end

function Node:sort(f)
    table.sort(self._order, f)
    return self
end

function Node:is_orphan()
    return self._children[".."] == nil
end

function Node:adopt(arg1, arg2)
    local function get_id()
        -- Maybe use some other way to generate UUID
        return type(arg1) == "string" and arg1 or lume.uuid()
    end

    local function get_node()
        return type(arg1) == "string" and arg2 or arg1
    end

    local name = get_id()
    local node = get_node()

    node:orphan()

    self._children[name] = node
    self._order[#self._order + 1] = node
    node._children[".."] = self

    if node.on_adopted then
        node:on_adopted(self, name)
    end
    return self, name
end

function Node:orphan(child)
    if child then
        local name = Dictionary.find(self._children, child)
        if not name then return end
        -- Remove links
        self._children[name] = nil
        child._children['..'] = nil
        -- Remove from order
        local index = List.argfind(self._order, child)
        if index then
            self._order = List.erase(self._order, index)
        end
    elseif not self:is_orphan() then
        local parent = self:find("..")
        parent:orphan(self)
    end

    return self
end

function Node:children()
    return self._children
end

function Node:child(arg1, ...)
    if type(arg1) == "string" then
        local name = arg1
        local node = Node.create(...)
        self:adopt(name, node)
        return node, name
    else
        local node = Node.create(arg1, ...)
        local _, id = self:adopt(node)
        return node, id
    end
end

function Node:fork(f, ...)
    if not f then return end
    -- Insert a reference to self as first argument
    local co = coroutine.create(f)
    -- Maybe it is unnecessary to
    self._threads[co] = true
    local status, msg = coroutine.resume(co, self, ...)
    if not status then
        log.error(msg)
    end
    return co
end

function Node:join(co)
    self._threads[co] = nil
    event:clear(co)
end

function Node:traverse(proc, args)
    args = args or {}

    local function do_traverse(node)
        local info = proc.enter and proc.enter(node, args) or {}
        if proc.visit then proc.visit(node, args, info) end

        local order = node._order
        local children = node._children

        for _, child in ipairs(order) do
            child = type(child) == "table" and child or children[child]
            if child then do_traverse(child) end
        end

        if proc.exit then proc.exit(node, args, info) end
    end

    return do_traverse(self)
end

return Node
