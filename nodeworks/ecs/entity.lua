local entity = {}
entity.__index = entity

function entity.create(world, tag)
    local this = {}
    this.world = world

    setmetatable(this, entity)
    return this:set_world(world):set_tag(tag)
end

function entity:set_tag(tag)
    self._tag = tag
    return self
end

function entity:__tostring()
    if self._tag then
        return string.format("Entity(%s)", self._tag)
    else
        return "Entity"
    end
end

function entity:add(component, ...)
    local t = type(component)

    local prev_value = self[component]

    if t == "function" then
        self[component] = component(...)
    elseif t == "table" then
        self[component] = component.create(...)
    else
        errorf("Unsupported type <%s>", t)
    end

    if self.world and prev_value == nil then
        self.world:entity_updated(self, component, prev_value, self[component])
    end

    return self
end

function entity:remove(component)
    if self[component] == nil then return self end

    local prev = self[component]
    self[component] = nil
    if self.world then self.world:entity_updated(self, component, prev) end
    return self
end

function entity:map(component, f, ...)
    if self[component] == nil then
        error("Attempted to map non-existing component")
    end

    return self:add(component, f(self[component], ...))
end

function entity:ensure(component, ...)
    if not self[component] then self:add(component, ...) end
    return self[component]
end


local function assemble_get_data(f, ...)
    local t = type(f)
    if t == "table" then
        return f
    elseif t == "function" then
        return f(...)
    else
        errorf("Unsupported type %s", t)
    end
end

function entity:assemble(f, ...)
    local data = assemble_get_data(f, ...)

    for component, args in pairs(data) do
        self:add(component, unpack(args))
    end

    return self
end

function entity:disassemble(f, ...)
    local data = assemble_get_data(f, ...)

    for component, args in pairs(data) do
        self:remove(component)
    end

    return self
end

function entity:get(component)
    return self[component]
end

function entity:has(first, ...)
    if not first then return false end

    local function __check_all(component, ...)
        if not component then return true end
        if not self[component] then return false end
        return __check_all(...)
    end

    return __check_all(first, ...)
end

function entity:has_assemblage(assemblage)
    local a = type(assemblage) == "function" and assemblage() or assemblage

    for component, _ in pairs(a) do
        if not self[component] then return false end
    end

    return true
end

function entity:set_world(world)
    if self.world then self.world:remove_entity(self)end

    self.world = world

    if self.world then self.world:add_entity(self) end
end

function entity:__mod(component)
    return self[component]
end

function entity:__add(component_args)
    local c = component_args[1]
    if not c then return self end
    if self[c] then
        return self:update(unpack(component_args))
    else
        return self:add(unpack(component_args))
    end
end

function entity:__sub(component)
    return self:remove(component)
end

function entity:__pow(assemble_args)
    return self:assemble(unpack(assemble_args))
end

return entity.create
