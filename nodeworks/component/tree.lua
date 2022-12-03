local Tree = class()

function Tree.create()
    return setmetatable(
        {
            _parent = {},
            _children = {},
            _alias = {}
        },
        Tree
    )
end

function Tree:children(node)
    self._children[node] = self._children[node] or list()
    return self._children[node]
end

function Tree:link(from, to)
    self._parent[to] = from
    table.insert(self:children(from), to)
    return self
end

function Tree:find(alias)
    return self._alias[alias]
end

function Tree:alias(name, node)
    self._alias[name] = node
end

return Tree.create
