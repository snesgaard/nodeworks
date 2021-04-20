local function get_frame(entity, index)
    return entity
        [components.animation_state]
        [components.frame_sequence]
        [index]
end

local function set_frame(entity, frame_index)
    local frame = get_frame(entity, frame_index)
    entity[components.animation_state]:update(index, frame_index)
    entity[components.animation_state]:update(timer, frame.dt)
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
    state:update(components.index, state[components.index] + 1)

    if state[components.index] > #state[components.frame_sequence] then
        if state[components.animation_args].once then
            state[components.animation_args].playing = false
            return
        end

        state:update(components.index, 1)
    end

    local frame = get_current_frame(entity)
    state:update(components.timer, frame.dt)
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

--- System Logic ---
local animation_system =  ecs.system(
    components.animation_state,
    components.sprite
)

function animation_system:update(dt)
    for _, entity in ipairs(self.pool) do
        update_animation(entity, dt)
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
    state:update(components.frame_sequence, sequence)
    state:update(components.animation_args, true, once, mode)
    set_frame(entity, 1)

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

function is_paused(entity)
    return not entity
        [components.animation_state]
        [components.animation_args]
        .playing
end

return animation_system
