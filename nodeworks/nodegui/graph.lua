local graph = {}
graph.__index = graph

function graph.create()
    return setmetatable({__children={}, __parents={}}, graph)
end

function graph:parent(id) return self.__parents[id] end

function graph:children(id) return self.__children[id] end

function graph:link(parent, child)
    self.__parents[child] = parent
    local pen = self.__children[parent] or {}
    table.insert(pen, child)
    self.__children[parent] = pen
end

return graph.create
