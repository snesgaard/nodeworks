local nw = require "nodeworks"

local slice_collision = {}

function slice_colliders.create_slice_id()
    return nw.ecs.id.weak("slice")
end

function slice_colliders.assemble_from_data(slice_data)
    return list()
end

function slice_colliders.spawn_slice(owner_id, name, rect, slice_data)
    local id = slice_colliders.create_slice_id(owner_id, name, rect, slice_data)

    stack.set(nw.component.owner, id, owner_id)
    local assemble = slice_colliders.assemble_from_data(slice_data) or list()
    stack.assemble(assemble, id)
    stack.assemble(
        {
            {nw.system.collision.register, rect},
            {nw.system.collision.flip_to, stack.get(nw.component.mirror, owner)}
        },
        id
    )

    return id
end

function slice_collision.spawn_slices(id)
    local slices, slice_data = sprite_animation.get_slices_and_data
    local last_slice = stack.get(nw.component.prev_slice, id)
    stack.set(nw.component.prev_slice, id, slices)

    if slices == last_slice then return end

    local slice_colliders = stack.ensure(nw.component.slice_colliders, id)

    -- Destroy previous colliders
    for _, slice_id in pairs(slice_colliders) do stack.detroy(slice_id) end

    local slice_colliders = {}

    -- Spawn slices
    for name, rect in pairs(slices) do
        slice_colliders[name] = spawn_slice(id, name, rect, slice_data[name] or {})
    end

    stack.set(nw.component.slice_colliders, id, slice_colliders)
end

function slice_collision.move_to_master(id)
    local slice_colliders = stack.get(nw.component.slice_colliders)
    if not slice_colliders then return end

    local p = stack.get(nw.component.position, id) or vec2()
    local m = stack.get(nw.component.mirror, id)
    for _, slice_id in pairs(slice_colliders) do
        collision.move_to(slice_id, p.x, p.y)
        collision.flip_to(slice_id, m)
    end
end

function slice_collision.update(dt)
    for id, _ in stack.view_table(nw.component.sprite_state) do
        slice_collision.spawn_slices(id)
    end

    for id, _ in stack.view_table(nw.component.sprite_state) do
        slice_collision.move_to_master(id)
    end
end

return slice_collision