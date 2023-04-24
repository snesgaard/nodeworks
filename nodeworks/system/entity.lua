local nw = require "nodeworks"

local component = {}

function component.create_request(order, id, func, ...)
    return {func = func, args = {...}, id = id, order = order}
end

function component.destroy_request(id)
    return {id = id}
end

function component.order(o) return o or 0 end

component.event = nw.component.relation(function(...) return list(...) end)

local Entity = nw.system.base()

function Entity:id_gen(ecs_world)
    return {}
end

function Entity:order_num(ecs_world)
    local entity = ecs_world:entity("__entity_sys__")
    local order = entity:ensure(component.order)
    entity:set(component.order, order + 1)
    return order
end

function Entity:make(ecs_world, ...)
    local id = self:id_gen(ecs_world)
    local order_num = self:order_num(ecs_world)

    ecs_world:entity()
        :set(component.create_request, order_num, id, ...)
        :set(nw.component.only_single_frame)

    return id
end

function Entity:destroy(ecs_world, id)
    ecs_world:entity()
        :set(component.destroy_request, id)
        :set(nw.component.only_single_frame)
end

function Entity:spin(ecs_world)
    local destroy_requests = ecs_world:get_component_table(component.destroy_request):values()
    local only_single_frame = ecs_world:get_component_table(nw.component.only_single_frame):keys()
    local create_requests = ecs_world:get_component_table(component.create_request)
        :values()
        :sort(function(a, b) return a.order < b.order end)


    for _, id in ipairs(only_single_frame) do
        ecs_world:destroy(id)
    end

    for _, dr in ipairs(destroy_requests) do
        ecs_world:destroy(dr.id)
    end

    for index, cr in ipairs(create_requests) do
        ecs_world:entity(cr.id)
            :set(nw.component.order, index)
            :assemble(cr.func, unpack(cr.args))
    end

    return create_requests:size()
end

local function assemble_from_event_comp(entity, event_component, ...)
    entity
        :set(event_component, ...)
        :set(nw.component.only_single_frame)
end

function Entity:emit(ecs_world, event_component, ...)
    local id = self:make(ecs_world, assemble_from_event_comp, event_component, ...)
    return event_component(...), id
end

function Entity:write_event(ecs_world, key, ...)
    local c = component.event(key)
    self:emit(ecs_world, c, ...)
end

function Entity:read_event(ecs_world, key)
    local c = component.event(key)
    return ecs_world:get_component_table(c)
end

function Entity:read(ecs_world, component)
    return ecs_world:get_component_table(component)
end

function Entity.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function Entity.handle_observables(ctx, obs, ...)
    for _, ecs_world in ipairs{...} do
        Entity.from_ctx(ctx):spin(ecs_world)
    end
end

return Entity.from_ctx