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
            return index, cycled_time - frame_time, false
        end

        frame_time = next_time
    end

    return #frames, time - cycled_time, true
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

AnimationMaster.EVENTS = {
    DONE = "animation:done",
    KEYFRAME = "animation:keyframe"
}

function AnimationMaster.create(world)
    return setmetatable({world=world}, AnimationMaster)
end

function AnimationMaster:emit(key, entity, ...)
    if not self.world then return end
    self.world:emit(key, entity, ...)
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

    local prev_index, _, is_done_prev = find_frame_index(state.time, state.frames, state.once)
    state.time = state.time + dt
    local next_index, _, is_done_next = find_frame_index(state.time, state.frames, state.once)

    if not is_done_prev and is_done_next then
        self:emit(self.EVENTS.DONE, entity, state.frames)
    end

    if prev_index ~= next_index and self.world then
        local prev_frame = state.frames[prev_index]
        local next_frame = state.frames[next_index]
        self:emit(self.EVENTS.KEYFRAME, entity, next_frame, prev_frame)
    end
end

function AnimationMaster:done(entity)
    local state = entity:get(nw.component.animation_state)
    if not state then return true end
    local total_animation_time = sum_frame_time(state.frames)
    return total_animation_time <= state.time
end

function AnimationMaster:get(entity)
    local state = entity:get(nw.component.animation_state)
    if not state then return end

    return find_frame(
        state.time, state.frames, state.once, state.ease or self.ease
    )
end

function AnimationMaster:play(entity, animation, once)
    local prev_state = entity:get(nw.component.animation_state)

    if prev_state then
        self:emit(self.EVENTS.DONE, entity, prev_state.frames)
    end

    entity:set(nw.component.animation_state, animation, once)

    self:emit(self.EVENTS.KEYFRAME, entity, self:get(entity))
    return self
end

function AnimationMaster:ensure(entity, animation, once)
    local prev_state = entity:get(nw.component.animation_state)
    local is_done = self:done(entity)
    if prev_state and prev_state.frames == animation and not is_done then return end

    return self:play(entity, animation, once)
end

function AnimationMaster:play_once(entity, animation)
    return self:play(entity, animation, true)
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

    self:emit(self.EVENTS.KEYFRAME, entity, self:get(entity))

    return self
end

function AnimationMaster.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function AnimationMaster.handle_observables(ctx, obs, ecs_world, ...)
    if not ecs_world then return end

    for _, dt in ipairs(obs.update:pop()) do
        AnimationMaster.from_ctx(ctx):update(dt, ecs_world)
    end

    return AnimationMaster.handle_observables(ctx, obs, ...)
end

local default_master = AnimationMaster.create()
function AnimationMaster.from_ctx(ctx)
    if not ctx then return default_master end

    local world = ctx.world or ctx
    world[AnimationMaster] = world[AnimationMaster] or AnimationMaster.create(world)
    return world[AnimationMaster]
end

return AnimationMaster.from_ctx
