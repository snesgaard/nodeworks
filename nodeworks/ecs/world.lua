local world = {}
world.__index = world

local function create()
    local this = {
        _entities = ecs.pool(),
        _system_stack = list(),
        _pools = dict(),
        _queue = list(),
        _spinning = false
    }
    return setmetatable(this, world)
end

function world:_pop_queue()
    local q = self._queue
    if #q > 0 then self._queue = list() end
    return q
end

function world:_get_pool(system)
    local p = self._pools[system]
    if p then return p end

    local alloc_p = ecs.pool()
    self._pools[system] = alloc_p
    return alloc_p
end

function world:spin()
    if self._spinning then return end

    self._spinning = true

    local queue = self:_pop_queue()

    while #queue > 0 do
        world:_handle_action(unpack(queue:head()))
        -- Add new events first, to make search depth first
        queue = self:_pop_queue() + queue:body()
    end

    self._spinning = false

    return self
end

function world:_handle_action(action, ...) return action(...) end

------------ ACTIONS -----------------

local function call_if_exists(f, ...)
    if f then return f(...) end
end

local function event(self, event, ...)
    local function pack_args(prev_args, first_arg, ...)
        if first_arg == nil then return prev_args end

        return {first_arg, ...}
    end

    local function invoke(args, system, ...)
        if List.head(args) == ecs.constants.block then return args end

        if not system then return args end

        local f = system[event]
        if not f then return invoke(args, ...) end

        local next_args = pack_args(
            args,
            f(self, self:_get_pool(system), unpack(args))
        )
        return _invoke(next_args, ...)
    end


    local args = {...}
    for i = #self._system_stack, 1, -1 do
        args = invoke(args, unpack(self._system_stack[i]))
    end
end

local function entity_updated(self, entity)
    local function handle_system(system, ...)
        if not system then return end

        local pool = self:_get_pool(system)
        local should_add = system.__pool_filter(entity)
        local is_added = pool[entity] ~= nil
        if should_add == is_added then return end

        if should_add then
            pool:add(entity)
            call_if_exists(system.on_entity_added, self, entity)
        else
            pool:remove(entity)
            call_if_exists(system.on_entity_removed, self, entity)
        end

        return handle_system(...)
    end

    for i = #self._system_stack, 1, -1 do
        handle_system(unpack(self._system_stack[i]))
    end
end

local function remove_entity(self, entity)
    local function handle_system(system, ...)
        local pool = self:_get_pool(system)
        if pool:remove(entity) then
            call_if_exists(system.on_entity_removed, self, entity)
        end
    end

    for i = #self._system_stack, 1, -1 do
        handle_system(unpack(self._system_stack[i]))
    end

    self._entities:remove(entity)

    return self
end

local function add_entity(self, entity)
    self._entities:add(entity)
    return entity_updated(self, entity)
end

local function push(self, systems)
    -- TODO: CHeck for duplicate systems
    table.insert(self._system_stack, systems)
    return self
end

local function pop(self)
    table.remove(self._system_stack, #systems)
    return self
end

local function move(self, systems)
    return self:pop():push(systems)
end

local actions_to_declare = {
    push=push, pop=pop, move=move, entity_updated=entity_updated,
    remove_entity=remove_entity, add_entity=add_entity,
    event=invoke_event
}

for name, action in pairs(actions_to_declare) do
    world[name] = function(self, ...)
        table.insert(self._queue, {action, ...})
        return self:spin()
    end
end

-----------------------------------------

function world:__call(...) return self:event(...) end

return create
