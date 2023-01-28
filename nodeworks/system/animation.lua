local nw = require "nodeworks"

local component = {}

function component.player(animation)
    return nw.animation.player(animation)
end

function component.hitbox_slices(slices)
    return slices or {}
end

component.animation_slice = nw.component.relation()

local assemble = {}

function assemble.slice_hitbox()

end

local function update_slices(entity, next_slices, assembly)
    local assembly = assembly or {}
    local relation = component.animation_slice:ensure(entity.id)
    local ecs_world = entity:world()
    
    local prev_slices = ecs_world:get_component_table(relation)
    
    for id, _ in pairs(prev_slices) do ecs_world:destroy(id) end
    
    local pos = entity:get(nw.component.position)
    if not pos then return end

    local created_slices = dict()

    for id, slice in pairs(next_slices) do
        local assemble_func = assembly[id]
        created_slices[id] = ecs_world:entity()
            :set(nw.component.mirror, entity:get(nw.component.mirror))
            :set(relation)
            :assemble(
                nw.system.collision().assemble.init_entity,
                pos.x, pos.y, slice
            )
            :assemble(nw.system.follow().follow, entity)
            :assemble(assemble_func)
    end

    return created_slices
end

local function on_update(entity, value, prev_value)
    if value.frame ~= prev_value.frame then
        entity:set(nw.component.frame, value.frame)
        --update_slices(entity, value.frame)
    end
end

local function slice_update_from_frame(entity, frame, assembly)
    local body_slices = dict()
    for id, _ in pairs(frame.slices) do
        body_slices[id] = frame:get_slice(id, "body")
    end
    update_slices(entity, body_slices, assembly)
end

local Animation = nw.system.base()

Animation.update_slices = update_slices
Animation.component = component

function Animation.on_entity_destroyed(id, values_destroyed, ecs_world)
    local relation = component.animation_slice:get(id)
    if not relation then return end
    local others = ecs_world:get_component_table(relation)
        :keys()

    for _, id in ipairs(others) do ecs_world:destroy(id) end
end

function Animation:play(entity, animation)
    local on_entity_destroyed = entity:world().on_entity_destroyed
    on_entity_destroyed.animation = on_entity_destroyed.animation or Animation.on_entity_destroyed

    local player = self:player(entity)
    if player and player.animation == animation then return player end
    entity:set(component.player, animation)
    local player = entity:get(component.player)
    local value = player:value()
    on_update(entity, value, {})
    return player
end

function Animation:stop(entity)
    entity:remove(component.player)
    return self
end

function Animation:play_once(entity, animation)
    local player = self:play(entity, animation)
    player:play_once()
    return player
end

function Animation:update_entity(entity, player, dt)
    local prev_value = player:value()
    local is_done = player:done()
    player:update(dt)
    local next_value = player:value()
    on_update(entity, next_value, prev_value)
    if player:done() and not is_done then
        self:emit("on_animation_done", entity, player.animation)
    end
end

function Animation:update(dt, ecs_world)
    local animation_table = ecs_world:get_component_table(component.player)
    for id, player in pairs(animation_table) do
        self:update_entity(ecs_world:entity(id), player, dt)
    end
end

function Animation:player(entity)
    return entity:get(component.player)
end

function Animation.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function Animation.handle_observables(ctx, obs, ecs_world)
    local sys = Animation.from_ctx(ctx)

    for _, dt in ipairs(obs.update:pop()) do
        self:update(dt, ecs_world)
    end
end

return Animation.from_ctx
