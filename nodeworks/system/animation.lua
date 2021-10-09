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
            return prev_frame
        end

        state:update(components.index, 1)
    end

    local frame = get_current_frame(entity)
    state:update(components.timer, frame.dt)
    return prev_frame, frame
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

local function format_event_begin(event)
    return string.format("animation_event:%s", event)
end

local function format_event_end(event)
    return string.format("animation_event:%s:end", event)
end

local function broadcast_event(world, entity, prev_frame, next_frame, id)
    if not world or prev_frame == next_frame then return end

    if prev_frame and not next_frame then
        world("on_animation_ended", entity, id, prev_frame)

        for event, _ in pairs(prev_frame.events) do
            local key = format_event_end(event)
            world(key, entity, prev_frame)
        end
    end

    if prev_frame and next_frame then
        world("on_next_frame", entity, prev_frame, next_frame, id)

        for event, _ in pairs(prev_frame.events) do
            if not next_frame.events[event] then
                world(format_event_end(event), entity, prev_frame)
            end
        end

        for event, _ in pairs(next_frame.events) do
            if not prev_frame.events[event] then
                world(format_event_begin(event), entity, prev_frame)
            end
        end

    end

    if not prev_frame and next_frame then
        world("on_animation_begun", entity, id, next_frame)

        for event, _ in pairs(next_frame.events) do
            local key = format_event_begin(event)
            world(key, event, next_frame)
        end
    end
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
        local prev_frame, next_frame = update_animation(entity, dt)
        update_sprite(entity)
        broadcast_event(
            self.world, entity, prev_frame, next_frame,
            entity[components.animation_state][components.animation_args].id
        )
    end
end

function animation_system.play(entity, id, args)
    args = args or {}
    local state = entity[components.animation_state]
    if not id then
        state[components.animation_args].playing = true
        return
    end

    local map = entity[components.animation_map]
    if not map then return false end
    local sequence = map[id]
    if not sequence then return false end

    local prev_frame = get_current_frame(entity)
    local prev_id = state[components.animation_args].id

    if sequence == state[components.frame_sequence] and not args.interrupt then return prev_frame end

    state:update(components.frame_sequence, sequence)
    state:update(components.animation_args, true, args.once, args.mode, id)
    set_frame(entity, 1)
    update_sprite(entity)

    local next_frame = get_current_frame(entity)

    -- First signal end of animation
    broadcast_event(entity.world, entity, prev_frame, nil, prev_id)
    -- Next signal start of the next animation
    broadcast_event(entity.world, entity, nil, next_frame, id)

    return next_frame
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

local function get_slice(entity, slice_name, body_slice, animation_tag, frame)
    local frame = frame or 1
    local map = entity[components.animation_map]
    if not map then return end
    local frames = map[animation_tag]
    if not frames then return end
    local frame = frames[frame]
    if not frame then return end
    local slice = frame.slices[slice_name] or spatial()
    local body = frame.slices[body_slice] or spatial()
    if not body then return slice end

    return slice:relative(body)
end

local function get_draw_args(entity)
    local sprite = entity[components.sprite]
    if not sprite then return components.draw_args() end
    return sprite[components.draw_args]
end

local function transform_slice(slice, position, sx, sy, mirror)
    sx = sx or 1
    sy = sy or sx
    if mirror then sx = -sx end

    local x, y = position:unpack()
    return slice:scale(sx, sy):sanitize():move(x, y)
end

function animation_system.transform_slice(entity, slice)
    if not slice or not entity then return end
    local draw_args = get_draw_args(entity)
    return transform_slice(
        slice,
        entity[components.position] or components.position(),
        draw_args.sx, draw_args.sy,
        entity[components.mirror]
    )
end

function animation_system.get_slice(entity, slice_name, body_slice, animation_tag, frame)
    local base_slice = get_slice(entity, slice_name, body_slice, animation_tag, frame) or spatial()
    local draw_args = get_draw_args(entity)
    return transform_slice(
        base_slice,
        entity[components.position] or components.position(),
        draw_args.sx, draw_args.sy,
        entity[components.mirror]
    )
end

function animation_system.get_base_slice(entity, slice_name, body_slice, animation_tag, frame)
    local base_slice = get_slice(entity, slice_name, body_slice, animation_tag, frame)
    local draw_args = get_draw_args(entity)
    return transform_slice(base_slice, vec2(), draw_args.sx, draw_args.sy, entity[components.mirror])
end

function is_paused(entity)
    return not entity
        [components.animation_state]
        [components.animation_args]
        .playing
end

return animation_system
