local node = {}
node.__index = node

function node.create(func, shader_str)
    local shader = nil
    if shader_str then
        shader = gfx.newShader(shader_str)
    end
    return setmetatable(
        {
            __func = func,
            __shader = shader
        },
        node
    )
end

local function should_realloc(canvas, w, h, args)
    local is_same = canvas:getWidth() == w and h == canvas:getHeight()
    return not is_same
end

local function should_realloc_all(canvases, args)
    if #canvases ~= #args then return true end

    for i = 1, #canvases do
        if should_realloc(canvases[i], unpack(args[i])) then return true end
    end

    return false
end

function node:canvas(first_arg, ...)
    local args = {first_arg, ...}

    if type(first_arg) == "number" then return self:canvas(args) end

    if not self.__canvas or should_realloc_all(self.__canvas, args) then
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
    if self.__shader then gfx.setShader(self.__shader) end
    local f = self.__func
    local out = {f(self, ...)}
    gfx.pop()
    return unpack(out)
end

function node:shader() return self.__shader end

return node.create
