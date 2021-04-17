--- Components ---
local function animation_map(atlas, animation_id_from_tag)
    local animation_map = {}

    for id, tag in pairs(animation_id_from_tag) do
        animation_map[id] = atlas:get_animation(tag)
    end

    return animation_map
end

local timer = components.timer
local function frame_sequence(s) return s or {} end
local function index(i) return i or 0 end
local function args(playing, once, mode)
    return {
        playing=playing or false,
        once=once or false,
        mode=mode or "forward"
    }
end

local state = ecs.assemblage(timer, frame_sequence, index, args)
--- /Components ---

--- System Logic ---
local system =  ecs.system{state, components.transform, components.sprite}

local function get_current_frame(entity)
    local i = entity[state][index]
    local fs = entity[state][frame_sequence]
    return fs[i]
end

local function should_be_updated(entity)
    return entity[state][args].playing
        and entity[state][frame_sequence] ~= nil
        and #entity[state][frame_sequence] > 0
end

local function update_animation(entity, dt)
    local state = entity[state]

    if not should_be_updated(entity) then return end
    if not state[timer]:update(dt) then return end
    state:update(index, state[index] + 1)

    if state[index] > #state[frame_sequence] then
        if state[args].once then
            state[args].playing = false
            return
        end

        state:update(index, 1)
    end

    local frame = get_current_frame(entity)
    state:update(timer, frame.dt)
end

local function update_sprite(entity)
    local sprite = entity[components.sprite]
    local frame = get_current_frame(entity)

    if not frame then return end

    sprite:update(components.image, frame.image, frame.quad)
    sprite[components.draw_args].ox = -frame.offset.x
    sprite[components.draw_args].oy = -frame.offset.y
end

function system:update(dt)
    for _, entity in ipairs(self.pool) do
        update_animation(entity, dt)
        update_sprite(entity)
    end
end

---

function get_frame(entity, frame_index)
    return entity[state][frame_sequence][frame_index]
end

function set_frame(entity, frame_index)
    local frame = get_frame(entity, frame_index)
    entity[state]:update(index, frame_index)
    entity[state]:update(timer, frame.dt)
end

function play(
    entity, id, once, mode)
    if not id then
        entity[state][args].playing = true
        return
    end

    local map = entity[animation_map]
    if not map then return false end
    local sequence = map[id]
    if not sequence then return false end
    entity[state]:update(frame_sequence, sequence)
    entity[state]:update(args, true, once, mode)
    set_frame(entity, 1)

    return true
end

function pause(entity)
    entity[state][args].playing = false
end

function stop(entity)
    entity[state][args].playing = false
    set_frame(entity, 1)
end

function is_paused(entity)
    return not entity[state][args].playing
end

return {
    play=play,
    stop=stop,
    pause=pause,
    system=system,
    state=state,
    map=animation_map,
    is_paused=is_paused
}
