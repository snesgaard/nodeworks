local im_animation = {}
im_animation.__index = im_animation

function im_animation.create()
    return setmetatable(
        {
            time = {},
            frames = {},
            once = {},
            paused = {}
        },
        im_animation
    )
end

function im_animation:set_ease(ease)
    self.ease = ease
    return self
end

function im_animation:update(dt)
    for id, t in pairs(self.time) do self.time[id] = t + dt end
    return self
end

local function sum_frame_time(frames)
    local time = 0
    for _, f in ipairs(frames) do time = time + (f.dt or 0) end
    return time
end

local function ease_frames(frames, index, time_in_frame, ease)
    local frame = frames[index]
    if not ease then return frame, false end

    local next_frame = frames[math.fmod(index, #frames) + 1]

    local im_frame = {}

    for key, value in pairs(frame) do
        local f = ease[key]
        local next_value = next_frame[key]
        if f and next_value ~= nil then
            im_frame[key] = f(time_in_frame, value, next_value - value, frame.dt)
        else
            im_frame[key] = value
        end
    end

    return im_frame, false
end

local function find_frame(self, time, frames, once)
    local time = math.max(0, time)
    local total_animation_time = sum_frame_time(frames)
    local cycled_time = once and time or math.fmod(time, total_animation_time)
    local ease = frames.ease or self.ease

    local frame_time = 0
    for index, frame in ipairs(frames) do
        local next_time = frame_time + (frame.dt or 0)

        if frame_time <= cycled_time and cycled_time < next_time then
            return ease_frames(frames, index, cycled_time - frame_time, ease)
        end

        frame_time = next_time
    end

    return List.tail(frames), true
end

function im_animation:get(id)
    local frames = self.frames[id]
    if not frames then return end
    local time = self.time[id] or 0

    return find_frame(self, time, frames, self.once[id])
end

function im_animation:set_animation_state(id, frames, time, once)
    self.frames[id] = frames
    self.time[id] = time or 0
    self.once[id] = once
end

function im_animation:play(id, frames)
    local prev_frames = self.frames[id]

    if prev_frames ~= frames then
        self:set_animation_state(id, frames)
    end

    return self:get(id)
end

function im_animation:ensure(id, frames)
    local prev_frames = self.frames[id]
    if prev_frames then return self:get(id) end

    return self:play(id, frames)
end

function im_animation:play_once(id, frames)
    local prev_frames = self.frames[id]

    if prev_frames ~= frames then
        self:set_animation_state(id, frames, nil, true)
    end

    return self:get_frame(id)
end

function im_animation:stop(id)
    return self:reset(id):pause()
end

function im_animation:reset(id)
    self.time[id] = 0
    return self
end

function im_animation:pause(id)
    self.paused[id] = true
    return self
end

return im_animation
