local render_graph = {}
render_graph.__index = render_graph

function render_graph.create(func)
    if not func then error("Function must not be nil") end

    local this = {__func=func, __links={}}
    return setmetatable(this, render_graph)
end

function render_graph:link(...)
    self.__links = {...}
    return self
end

function render_graph:__call()
    if self.__cache then return self.__cache end
    gfx.push("all")
    local r = self.__func(self, self:__eval_links())
    gfx.pop()
    self.__cache = r
    return r
end

function render_graph:__eval_links()
    local function do_eval(node, ...)
        if not node then return end
        return node(), do_eval(...)
    end

    return do_eval(unpack(self.__links))
end

function render_graph:clear(just_this_node)
    self.__cache = nil
    if just_this_node then return end
    for _, node in ipairs(self.__links) do node:clear() end
end

function render_graph:draw(x, y)
    local buffer = self()
    gfx.setBlendMode("alpha")
    gfx.setCanvas()
    gfx.draw(buffer, x or 0, y or 0)
    self:clear()
end

return render_graph.create
