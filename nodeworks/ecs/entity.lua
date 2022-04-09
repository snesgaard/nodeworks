local function raw_set(self, component, next_value)
    local prev_value = self[component]
    self[component] = next_value
    if self.world then
        self.world:notify_change(self, component, prev_value, next_value)
    end
    return self
end

local entity = {}
entity.__index = entity

function entity:has(component) return self[component] ~= nil end

function entity:set(component, ...)
    return raw_set(self, component, component(...))
end

function entity:get(component) return self[component] end

function entity:ensure(component, ...)
    if not self:has(component) then self:set(component, ...) end
    return self:get(component)
end

function entity:map(component, func, ...)
    local value = self:get(component)
    local next_value = func(value, ...)
    return raw_set(self, component, next_value)
end

function entity:visit(func, ...)
    func(self, ...)
    return self
end

function entity:set_world(world)
    local prev_world = self.world
    local next_world = world

    self.world = next_world

    if prev_world then
        for component, value in pairs(self) do
            if type(component) ~= "string" then
                prev_world:notify_change(self, component, value, nil)
            end
        end
    end

    if next_world then
        for component, value in pairs(self) do
            if type(component) ~= "string" then
                next_world:notify_change(self, component, nil, value)
            end
        end
    end

    return self
end

function entity:destroy() return self:set_world(nil) end

function entity:set_tag(tag)
    self.tag = tag
    return self
end

function entity:__tostring()
    if self.tag then
        return string.format("Entity[%s]", tostring(self.tag))
    else
        return "Entity"
    end
end

function entity:__add(component, ...) return self:set(component, ...) end

function entity:__mod(component) return self:get(component) end

return function() return setmetatable({}, entity) end
