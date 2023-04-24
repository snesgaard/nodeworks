local weak_table = {__mode = "k"}

local entity = {}
entity.__index = entity


function entity.create(table, id)
    return setmetatable({id=id or {}, table=table}, entity)
end

function entity:__tostring()
    local id = tostring(self.id)
    return string.format("Entity [%s]", id)
end

function entity:set(component, ...)
    self.table:set(component, self.id, ...)
    return self
end

function entity:init(component, ...)
    self.table:init(component, self.id, ...)
    return self
end

function entity:has(component)
    return self.table:has(component, self.id)
end

function entity:get(component)
    return self.table:get(component, self.id)
end

function entity:maybe_get(component)
    return self.table:maybe_get(component, self.id)
end

function entity:ensure(component, ...)
    return self.table:ensure(component, self.id, ...)
end

function entity:map(component, func, ...)
    self.table:map(component, self.id, func, ...)
    return self
end

function entity:remove(component)
    self.table:remove(component, self.id)
    return self
end

function entity:assemble(func, ...)
    if func then func(self, ...) end
    return self
end

function entity:world() return self.table end

function entity:destroy() return self:world():destroy(self.id) end

function entity:__mod(component) return self:get(component) end

local entity_table = {}
entity_table.__index = entity_table

function entity_table.create()
    return setmetatable(
        {
            components = {},
            stored_entities = {},
            foreign_component = {},
            on_entity_destroyed = {}
        },
        entity_table
    )
end

function entity_table:copy()
    local next_entity = entity_table.create()

    for comp, comp_table in pairs(self.components) do
        next_entity.components[comp] = comp_table
        next_entity.foreign_component[comp] = true
    end

    return next_entity
end

function entity_table:entity(id)
    local id = id or {}
    if not self.stored_entities[id] then
        self.stored_entities[id] = entity.create(self, id)
    end
    return self.stored_entities[id]
end

local function fetch_component(self, component)
    if component == nil then error("component was nil") end
    local c = self.components[component]
    if c then return c end
    local c = dict()
    self.components[component] = c
    return c
end

local function handle_copy_on_write(self, component)
    if not self.foreign_component[component] then return end
    local c = self.components[component]
    if not c then return end
    self.foreign_component[component] = false
    self.components[component] = dict(c)
end

local function raw_set_component(self, component, id, value)
    if id == nil then error("Id was nil") end
    handle_copy_on_write(self, component)
    local c = fetch_component(self, component)
    local prev_value = c[id]
    c[id] = value
    if type(prev_value) == "table" and prev_value.destroy then prev_value:destroy() end
    return self
end

function entity_table:set(component, id, ...)
    return raw_set_component(self, component, id, component(...))
end

function entity_table:init(component, id, ...)
    if not self:has(component, id) then self:set(component, id, ...) end
    return self
end

function entity_table:remove(component, id)
    return raw_set_component(self, component, id)
end

function entity_table:get(component, id)
    return fetch_component(self, component)[id]
end

function entity_table:maybe_get(component, id)
    if self:has(component, id) then
        return Result.just(self:get(component, id))
    else
        return Result.empty()
    end
end

function entity_table:get_component_table(component)
    return fetch_component(self, component)
end

function entity_table:has(component, id)
    return self:get(component, id) ~= nil
end

function entity_table:map(component, id, func, ...)
    local value = self:ensure(component, id)
    if value == nil then return self end
    return raw_set_component(self, component, id, func(value, ...))
end

function entity_table:ensure(component, id, ...)
    local value = self:get(component, id)
    if value ~= nil then return value end
    local next_value = component(...)
    raw_set_component(self, component, id, next_value)
    return next_value
end

function entity_table:destroy(id)
    local values_destroyed = dict()

    for component, values in pairs(self.components) do
        values_destroyed[component] = values[id]
        self:remove(component, id)
    end

    if self.on_entity_destroyed then
        for _, func in pairs(self.on_entity_destroyed) do
            func(id, values_destroyed, self)
        end
    end

    self.stored_entities[id] = nil

    return values_destroyed
end

function entity_table:pool(...)
    local components = list(...)
    local entity_count = {}

    for _, comp in ipairs(components) do
        for entity, _ in pairs(fetch_component(self, comp)) do
            entity_count[entity] = (entity_count[entity] or 0) + 1
        end
    end

    local result = list()

    for entity, count in pairs(entity_count) do
        if count == #components then table.insert(result, entity) end
    end

    return entity
end

local function get_component_table(comp, ecs_world) return ecs_world:get_component_table(comp) or dict() end
local function sort_by_size(a, b) return a:size() < b:size() end
local function is_id_in_all(id, component_tables)
    for _, cb in ipairs(component_tables) do
        if not cb[id] then return false end
    end

    return true
end

function entity_table:filter_id_on_component(components)
    local component_tables = components
        :map(get_component_table, self)
        :sort(sort_by_size)
    
    return component_tables
        :head()
        :keys()
        :filter(is_id_in_all, component_tables)
end

local function perform_component_lookup(comp, ecs_world, id)
    return ecs_world:get(comp, id)
end

local function join_iter(id_to_value, key)
    local next_key, next_value = next(id_to_value, key)
    if next_value then
        return next_key, unpack(next_value)
    else
        return next_key
    end
end

function entity_table:join(...)
    local components = list(...)
    local ids = self:filter_id_on_component(components)
    local id_to_value = dict()

    for _, id in ipairs(ids) do
        id_to_value[id] = components:map(perform_component_lookup, self, id)
    end

    return join_iter, id_to_value
end

function entity_table:table(component)
    return self:get_component_table(component)
end

return entity_table
