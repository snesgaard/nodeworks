local layer = {}
layer.__index = layer

function layer.create()
    return setmetatable(
        {
            stack = stack(),
            state = list()
        },
        layer
    )
end

function layer:push()
    self.stack:push(self.state:copy())
    return self
end

function layer:pop()
    local prev_state = self.stack:pop()
    if not prev_state then
        error("Tried to pop state, but there was none")
    end
    self.state = prev_state
    return self
end

function layer:add(func, ...)
    local content = {func, ...}
    table.insert(self.state, content)
    return self
end

local function invoke(func, ...) return func(...) end

function layer:draw()
    for _, draw_args in ipairs(self.state) do invoke(unpack(draw_args)) end
end

local layer_manager = {}
layer_manager.__index = layer_manager

function layer_manager.create()
    return setmetatable({}, layer_manager)
end

function layer_manager:__call(key)
    local l = self[key]
    if not l then self[key] = layer.create() end
    return self[key]
end

return layer_manager.create
