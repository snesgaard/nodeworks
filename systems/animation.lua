local function get_frame(entity, index)
    return entity
        [components.animation_state]
        [components.frame_sequence]
        [index]
end

local function set_frame(entity, frame_index)
    local frame = get_frame(entity, frame_index)
    entity[components.animation_state]:update(components.index, frame_index)
    entity[components.animation_state]:update(components.timer, frame.dt)
end

local function get_current_frame(entity)
    local i = entity
        [components.animation_state]
        [components.index]
    local fs = entity
        [components.animation_state]
        [components.frame_sequence]
    return fs[i]
end

local function should_be_updated(entity)
    local state = entity[components.animation_state]
    local fs = state[components.frame_sequence]
    return state[components.animation_args].playing and fs ~= nil and #fs > 0
end

local function update_animation(entity, dt)
    local state = entity[components.animation_state]

    if not should_be_updated(entity) then return end
    if not state[components.timer]:update(dt) then return end
    local prev_frame = get_current_frame(entity)
    state:update(components.index, state[components.index] + 1)

    if state[components.index] > #state[components.frame_sequence] then
        if state[components.animation_args].once then
            state[components.animation_args].playing = false
            return "on_animation_ended"
        end

        state:update(components.index, 1)
    end

    local frame = get_current_frame(entity)
    state:update(components.timer, frame.dt)
    return "on_next_frame", prev_frame, frame
end

local function update_sprite(entity)
    local sprite = entity[components.sprite]
    local frame = get_current_frame(entity)

    if not frame then return end

    sprite:update(components.image, frame.image, frame.quad)
    sprite[components.draw_args].ox = -frame.offset.x
    sprite[components.draw_args].oy = -frame.offset.y
    sprite:update(components.slices, frame.slices)
end

local function handle_event(world, entity, event_key, ...)
    if not event_key then return end
    world(event_key, entity, ...)
end

--- System Logic ---
local animation_system =  ecs.system(
    components.animation_state,
    components.sprite
)

function animation_system:update(dt)
    for _, entity in ipairs(self.pool) do
        handle_event(self.world, entity, update_animation(entity, dt))
        update_sprite(entity)
    end
end

function animation_system.play(entity, id, once, mode)
    local state = entity[components.animation_state]
    if not id then
        state[components.animation_args].playing = true
        return
    end

    local map = entity[components.animation_map]
    if not map then return false end
    local sequence = map[id]
    if not sequence then return false end
    if sequence == state[components.frame_sequence] then return true end
    state:update(components.frame_sequence, sequence)
    state:update(components.animation_args, true, once, mode)
    set_frame(entity, 1)
    update_sprite(entity)

    return true
end

function animation_system.pause(entity)
    entity
        [components.animation_state]
        [components.animation_args]
        .playing = false
end

function animation_system.stop(entity)
    entity
        [components.animation_state]
        [components.animation_args]
        .playing = false
    set_frame(entity, 1)
end

function animation_system.__get_slice(entity, slice_name, body_slice, animation_tag, frame)
    local frame = frame or 1
    local map = entity[components.animation_map]
    if not map then return end
    local frames = map[animation_tag]
    if not frames then return end
    local frame = frames[frame]
    if not frame then return end
    local slice = frame.slices[slice_name]
    local body = frame.slices[body_slice]
    if not body then return slice end

    return slice:relative(body)
end

function animation_system.get_draw_args(entity)
    local sprite = entity[components.sprite]
    if not sprite then return components.draw_args() end
    return sprite[components.draw_args]
end

function animation_system.transform_slice(slice, position, sx, sy, mirror)
    sx = sx or 1
    sy = sy or sx
    if mirror then sx = -sx end

    local x, y = position:unpack()
    return slice:scale(sx, sy):sanitize():move(x, y)
end

function animation_system.get_slice(entity, slice_name, body_slice, animation_tag, frame)
    local base_slice = animation_system.__get_slice(entity, slice_name, body_slice, animation_tag, frame)
    local draw_args = animation_system.get_draw_args(entity)
    return animation_system.transform_slice(
        base_slice,
        entity[components.position] or components.position(),
        draw_args.sx, draw_args.sy,
        entity[components.mirror]
    )
end

function animation_system.get_base_slice(entity, slice_name, body_slice, animation_tag, frame)
    local base_slice = animation_system.__get_slice(entity, slice_name, body_slice, animation_tag, frame)
    return base_slice
end

function is_paused(entity)
    return not entity
        [components.animation_state]
        [components.animation_args]
        .playing
end

return animation_system
