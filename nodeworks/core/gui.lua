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

local gui = {}
gui.__index = gui

function gui.create(base, ...)
    local this = setmetatable(
         {
             base=base,
             tweens={},
             animations={}
         },
         gui
    )

    return this:init(...)
end

function gui:init(...)
    self.state = self.base.init(...)
    return self
end

local function handle_action_return(self, state, ...)
    self.state = state or self.state
    return ...
end

function gui:action(key, ...)
    local f = self.base[key]
    if not f then return end
    return handle_action_return(self, f(self, self.state, ...))
end

function gui:draw(...)
    local f = self.base.draw
    local s = self.state
    if not s or not f then return end
    f(self, s)
end

function gui:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end

    for _, anime in pairs(self.animations) do anime:update(dt) end

    return self:action("update", dt)
end

function gui:tween(key)
    local t = self.tweens[key]
    if not t then
        local t = imtween.create()
        self.tweens[key] = t
        return t
    else
        return t
    end
end

function gui:animation(id)
    local id = id or "default"
    local a = self.animations[id]
    if not a then
        local a = im_animation.create()
        self.animations[id] = a
        return a
    else
        return a
    end
end

function gui:__call(...) return self:action(...) end

return gui.create
