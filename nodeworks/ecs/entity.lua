local entity = {}
entity.__index = entity

function entity.create(world, tag)
    return setmetatable(
        {
            world = world,
            tag = tag,
            dead = false,
            changed = false,
            past = dict()
        },
        entity
    )
end

function entity:__tostring()
    if self.tag then
        return string.format("entity[%s]", self.tag)
    else
        return "entity"
    end
end

function entity:is_dead() return self.dead end

function entity:notify_change()
    if self.world and not self.dead then self.world:notify_change(self) end
    return self
end

function entity:set_past(component, value)
    self.past[component] = self.past[component] or value
    self.changed = true
    return self
end

function entity:pop_past()
    if not self.changed then return self.past end
    self.changed = false
    local p = self.past
    self.past = dict()
    return p
end

local function evaluate_component(component, ...)
    if type(component) == "function" then
        return component(...)
    elseif type(component) == "table" then
        return component.create(...)
    else
        errorf("Unsupported type %s", tostring(type(component)))
    end
end

function entity:set(component, ...)
    local prev_value = self[component]
    local next_value = evaluate_component(component, ...)
    self:set_past(component, prev_value)
    self[component] = next_value
    return self:notify_change()
end

function entity:get(component) return self[component] end

function entity:check(component) return self[component] or component() end

function entity:remove(component)
    local prev_value = self[component]
    if not prev_value then return self end
    self:set_past(component, prev_value)
    self[component] = nil
    return self:notify_change()
end

function entity:destroy()
    self.dead = true
    return self:notify_change()
end

function entity:has_changed()
    return self.dead or self.changed
end

function entity:assemble(assemblage, ...)
    assemblage(self, ...)
    return self
end

function entity:ensure(component, ...)
    if not self:has(component) then self:set(component, ...) end
    return self:get(component)
end

function entity:has(component) return self[component] ~= nil end

function entity:map(component, func, ...)
    if not self:has(component) then return self end
    return self:set(component, func(self:get(component), ...))
end

function entity:__add(args) return self:set(unpack(args)) end

function entity:__mod(component) return self:get(component) end

return entity.create
