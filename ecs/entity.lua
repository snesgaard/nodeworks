local entity = {}
entity.__index = entity

function entity.create(world)
    local this = {}
    this.world = world

    setmetatable(this, entity)

    if world then world:update(this) end
    return  this
end

function entity:__tostring()
    return "Entity"
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
    if self.world then self.world:update(self, ...) end

    return self
end

function entity:update(component, ...)
    local prev_value = self[component]

    if prev_value == nil then return self end

    local t = type(component)
    if t == "function" then
        self[component] = component(...)
    elseif t == "table" then
        self[component] = component.create(...)
    else
         errorf("Unsupported type <%s>", t)
    end

    if self.world then self.world:update(self, component, prev_value, self[component]) end

    return self

end

function entity:map(component, f, ...)
    if self[component] == nil then return self end

    return self:update(component, f(self[component], ...))
end

function entity:assemble(func, ...)
    func(self, ...)

    if self.world then self.world:update(self) end
    return self
end

function entity:remove(component)
    local prev = self[component]
    self[component] = nil
    if self.world then self.world:update(self, component, prev) end
    return self
end

function entity:get(component)
    return self[component]
end

function entity:has(...)
    for _, component in ipairs({...}) do
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
    self.world = nil
end

function entity:event(event, ...)
    self:add(event, ...)
    self:remove(event)
    return self
end

return entity.create
