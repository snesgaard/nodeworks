local nw = require "nodeworks"

local world = {}
world.__index = world

function world.create()
    return setmetatable(
        {
            entities = nw.ecs.pool(),
            system_stack = stack(),
            pools = dict(),
            changed_entities = list(),
            event_queue = event_queue()
        },
        world
    )
end

local function call_if_exists(f, ...) if f then return f(...) end end

function world:notify_change(entity)
    table.insert(changed_entities, entity)
    return self
end

function world:entity(tag)
    return nw.ecs.entity(world, tag)
end

function world:singleton()
    if not self.singleton_entity then
        self.singleton_entity = self:entity("singleton")
    end

    return self.singleton_entity
end

function world:resolve_changed_entities()
    if self.changed_entities:empty() then return end

    local function handle_change(system, entity, past)
        local pool = self:get_pool(system)
        local is_there = pool[entity]
        local should_be_there = system.entity_filter(entity)

        if not is_there and not should_be_there then return end

        if not is_there and should_be_there then
            pool:add(entity)
            call_if_exists(system.on_entity_added, self, entity)
        elseif is_there and should_be_there then
            call_if_exists(system.on_entity_changed, self, entity, past)
        else
            call_if_exists(system.on_entity_removed, self, entity, past)
            pool:remove(entity)
        end
    end

    local function handle_dead(system, entity, past)
        local pool = self:get_pool(system)
        if not pool[entity] then return end

        call_if_exists(system.on_entity_removed, self, entity, past)
        pool:remove(entity)
    end

    local function handle_entity(entity)
        if not entity:has_changed() then return end

        local past = entity:pop_past()
        if not entity:is_dead() then
            self.entities:add(entity)
            system_stack:foreach(List.foreach, handle_change, entity, past)
        else
            system_stack:foreach(List.foreach, handle_dead, entity, past)
            self.entites:remove(entity)
        end
    end

    local changed_entities = self.changed_entities
    self.changed_entities = list()

    return changed_entities:foreach(handle_entity)
end

local implementation = {}

function implementation.event(self, event_key, ...)
    local unpack = unpack

    local function pack_args(args, first, ...)
        if first == nil then return args end
        return {first, ...}
    end

    local function handle_system(system, args)
        local f = system[event_key]
        if not f then return end
        -- Make sure pools are up to date before fetching them
        self:resolve_changed_entities()
        return pack_args(
            args,
            f(self, self:get_pool(system), unpack(args))
        )
    end

    local function should_stop(args)
        return List.head(args) == nw.ecs.constants.block
    end

    local args = {...}
    for i = self.system_stack:size(), 1, -1 do
        local systems = self.system_stack[i] do
            for _, system in ipairs(systems) do
                args = handle_system(system, args)
                if should_stop(args) then return end
            end
        end
    end
end

function implementation.push(self, systems)

    self:resolve_changed_entities()
    self.system_stack = self.system_stack:push(systems)

    local function handle_system_and_entity(system, entity)
        local pool = self:get_pool(system)
        local is_there = pool[entity]
        local should_be_there = system.entity_filter(entity)
        if not (not is_there and should_be_there) then return end
        pool:add(entity)
        call_if_exists(system.on_entity_added, self, entity)
    end

    local function handle_entity(entity)
        List.foreach(systems, handle_system_and_entity, entity)
    end

    List.foreach(self.entities, handle_entity)

    List.foreach(
        sytems,
        function(system)
            call_if_exists(system.on_pushed, self, self:pool(system))
        end
    )
end

function implementation.pop(self)
    local next_stack, systems = self.system_stack:pop()
    if not systems then return end

    self:resolve_changed_entities()
    self.system_stack = next_stack

    local function handle_system(system)
        local pool = self:get_pool(system)
        self:clear_pool(system)
        call_if_exists(system.on_poped, self, pool)

        local empty_past = {}
        for _, entity in ipairs(pool) do
            call_if_exists(system.on_entity_removed, self, entity, empty_past)
        end
    end

    List.foeach(systems, handle_system)
end

function implementation.move(self, system)
    implementation.pop(self)
    implementation.push(self, systems)
end

for name, func in pairs(implementation) do
    world[name] = function(self, ...)
        return self.event_queue(func, self, ...)
    end
end

return world.create
