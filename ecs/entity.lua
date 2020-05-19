local entity = {}

function entity.create(world)
    local this = {}
    this.world = world

    if world then
        world:add(this)
    end
    return setmetatable(this, entity)
end

function entity:add(component, ...)
    self[component] = component(...)
    return self
end

function entity:remove(component)
    self[component] = nil
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

    if self.world then self.world:add(self) end
end

function entity:destroy()
    if self.world then self.world:remove(self) end
end

return entity.create
