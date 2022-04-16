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
    for _, draw_args in ipairs(self.state) do
        if invoke(unpack(draw_args)) then return true end
    end

    return false
end

function layer:clear()
    self.state = list()
    return self
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

function layer_manager:clear()
    for key, layer in pairs(self) do layer:clear() end
end

return layer_manager.create
