local node = {}
node.__index = node

function node.create(func, ...)
    return setmetatable(
        {
            __func = func
        },
        node
    )
end

function node:canvas(first_arg, ...)
    local args = {first_arg, ...}

    if type(first_arg) == "number" then return self:canvas(args) end

    if not self.__canvas then
        self.__canvas = List.map(
            args,
            function(arg) return gfx.newCanvas(unpack(arg)) end
        )
    end

    gfx.setCanvas(unpack(self.__canvas))

    return unpack(self.__canvas)
end

function node:__call(...)
    gfx.push('all')
    local f = self.__func
    local out = {f(self, ...)}
    gfx.pop()
    return unpack(out)
end

return node
