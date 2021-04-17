local entity = {}
entity.__index = entity

function entity.create(world)
    local this = {}
    this.world = world

    if world then
        world:update(this)
    end
    return setmetatable(this, entity)
end

function entity:add(component, ...)
    local t = type(component)
    if t == "function" then
        self[component] = component(...)
    elseif t == "table" then
        self[component] = component.create(...)
    else
        errorf("Unsupported type <%s>", t)
    end

    if self.world then self.world:update(self) end

    return self
end

function entity:update(component, ...)
    if not self[component] then return end

    local t = type(component)
    if t == "function" then
        self[component] = component(...)
    elseif t == "table" then
        self[component] = component.create(...)
    else
        errorf("Unsupported type <%s>", t)
    end

    return self
end

function entity:assemble(func, ...)
    func(self, ...)

    if self.world then self.world:update(self) end
    return self
end

function entity:remove(component)
    self[component] = nil
    if self.world then self.world:update(self) end
    return self
end

function entity:get(component)
    return self[component]
end

function entity:has(components)
    for _, component in ipairs(components) do
        if not self[component] then return false end
    end
    return true
end

function entity:set_world(world)
    if self.world then self.world:remove(self)end

    self.world = world

    if self.world then self.world:update(self) end
end

function entity:destroy()
    if self.world then self.world:remove(self) end
end

return entity.create
