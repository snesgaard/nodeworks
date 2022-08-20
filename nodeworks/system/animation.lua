local nw = require "nodeworks"

--[[
animation(ctx):entity(ecs_world, id)
    :play(anime.necro.idle)
    :once()
    :foreach_frame(assign_values)
    :foreach_keyframe(sync_hitbox)

]]--

local function sum_frame_time(frames)
    local time = 0
    for _, f in ipairs(frames) do time = time + (f.dt or 0) end
    return time
end

local function ease_frames(prev_frame, next_frame, time_from_prev, ease)
    if not ease then return prev_frame end

    local im_frame = {}

    for key, value in pairs(prev_frame) do
        local f = ease[key]
        local next_value = next_frame[key]
        if f and next_value ~= nil then
            im_frame[key] = f(
                time_from_prev, value, next_value - value, prev_frame.dt
            )
        else
            im_frame[key] = value
        end
    end

    return im_frame, false
end

local function find_frame_index(time, frames, once)
    local total_animation_time = sum_frame_time(frames)
    local cycled_time = once and time or math.fmod(time, total_animation_time)

    if time < 0 then return 0, time end

    local frame_time = 0

    for index, frame in ipairs(frames) do
        local next_time = frame_time + (frame.dt or 0)

        if frame_time <= cycled_time and cycled_time < next_time then
            return index, cycled_time - frame_time
        end

        frame_time = next_time
    end

    return #frames, time - cycled_time
end

local function find_frame(time, frames, once, default_ease)
    local index, time_from_prev = find_frame_index(time, frames, once)
    local ease = frames.ease or default_ease
    local prev_frame = frames[index]
    local next_frame = frames[index + 1]

    if not prev_frame and next_frame then return next_frame end
    if prev_frame and not next_frame then return prev_frame end

    return ease_frames(prev_frame, next_frame, time_from_prev, ease)
end

local AnimationMaster = class()

function AnimationMaster.create(world)
    return setmetatable({world=world}, AnimationMaster)
end

function AnimationMaster:update(dt, ...)
    for _, ecs_world in ipairs{...} do
        local entities = ecs_world:get_component_table(
            nw.component.animation_state
        )

        for entity, state in pairs(entities) do
            self:update_entity_state(entity, state, dt)
        end
    end
end

function AnimationMaster:update_entity_state(entity, state, dt)
    if state.paused then return end

    local prev_index = find_frame_index(state.time, state.frames, state.once)
    state.time = state.time + dt
    local next_index = find_frame_index(state.time, state.frames, state.once)

    if prev_index ~= next_index and self.world then
        local prev_frame = state.frames[prev_index]
        local next_frame = state.frames[next_index]
        self.world:emit(entity, "animation:keyframe", next_frame, prev_frame)
        -- Handle keyframe
    end
end

function AnimationMaster:get(entity)
    local state = entity:get(nw.component.animation_state)
    if not state then return end

    return find_frame(
        state.time, state.frames, state.once, state.ease or self.ease
    )
end

function AnimationMaster:play(entity, animation)
    entity:set(nw.component.animation_state, animation)
    return self
end

function AnimationMaster:play_once(entity, animation)
    entity:set(nw.component.animation_state, animation, true)
    return self
end

function AnimationMaster:pause(entity)
    local state = entity:get(nw.component.animation_state)
    if not state then return self end
    state.paused = true
    return self
end

function AnimationMaster:unpause(entity)
    local state = entity:get(nw.component.animation_state)
    if not state then return self end
    state.paused = false
    return self
end

function AnimationMaster:stop(entity)
    local state = entity:get(nw.component.animation_state)
    if not state then return self end
    state.paused = true
    state.time = 0
    return self
end

local default_master = AnimationMaster.create()

return function(ctx)
    if not ctx then return default_master end

    local world = ctx.world or ctx
    world[AnimationMaster] = world[AnimationMaster] or AnimationMaster.create(world)
    return world[AnimationMaster]
end
