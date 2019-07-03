local function search_time(time)
    return function(t)
        return time <= t
    end
end

local track = {}
track.__index = track

function track.create(values, times, agg)
    local this = {
        __values = values,
        __times = times,
        __agg = agg,
        __size = math.min(#values, #times),
        __time = 0
    }
    return setmetatable(this, track)
end

function track:set_ease(ease)
    self.__ease = ease
    return self
end

function track:set_time(time)
    self.__time = time
    return self
end

function track:set_agg(agg)
    self.__agg = agg
    return self
end

function track:get_frame(frame)
    return self.__values[frame], self.__times[frame]
end

function track:get_value(time)
    if self.__size <= 0 then return end
    time = time or self.__time

    local frame = self.__times:argfind(search_time(time)) or self.__size

    if frame == 1 or frame == self.__size or not self.__ease then
        local v1 = self:get_frame(frame)
        return v1
    elseif frame and self.__ease then
        local v1, t1 = self:get_frame(frame)
        local v2, t2 = self:get_frame(frame + 1)
        local d = t2 - t1
        local c = v2 - v1
        local t = time - t1
        return self.__ease(t, f1.value, c, d)
    end
end

function track:update(dt)
    self.__time = self.__time + dt
end

local calltrack = {}
calltrack.__index = calltrack

function calltrack.create(calls, args, times)
    local this = {
        __calls = calls,
        __times = times
        __args = args,
        __size = math.min(#calls, #args, #times)
        __time = 0,
    }
    return setmetatable(this, calltrack)
end

function callback:get_frame(frame)
    return self.__calls[frame], self.__args[frame] or {}
end

function calltrack:invoke_call(t1, t2)
    t1 = t1 or self.__prev_time
    t2 = t2 or self.__time
    local f1 = self.__times:argfind(search_time(t1)) or self.__size
    local f2 = self.__times:argfind(search_time(t2)) or self.__size

    local d = f1 <= f2 and 1 or -1

    for i = f1 + 1, f2, d do
        local c, a = self:get_frame(i)
        c(unpack(a))
    end
end

function calltrack:update(dt)
    self.__prev_time = self.__time
    self.__time = self.__time + dt
end

function calltrack:set_time(t1, t2)
    if t1 and not t2 then
        self.__prev_time = self.__time
        self.__time = t1
        self:invoke_call()
    elseif t1 and t2 then
        self.__prev_time = t1
        self.__time = t2
        self:invoke_call()
    end
end

local animation = {}
animation.__index = animation

function animation.create()
    local self = {}
    self.__tracks = {}
    self.__nodes = {}
    self.__keys = {}
    self.__prev_value = {}
    self.__time = 0
    self.__duration = 0
    self.__loop = false
    return setmetatable(self, animation)
end

function animation:set_loop(loop)
    self.__loop = loop
    return self
end

function animation:set_duration(d)
    self.__duration = 0
    return self
end

function animation:reset()
    self.__time = 0
end

function animation:track(node, key, ...)
    self.__tracks[#self.__tracks + 1] = track.create(...)
    self.__nodes[#self.__nodes + 1] = node
    self.__keys[#self.__keys + 1] = key
    return track
end

function animation:update(dt)
    self.__time = self.__time + dt

    if self.__duration < self.__time and self.__loop then
        return self:update(-self.__duration)
    end
end

function animation:set_time(time)
    return animation:update(time - self.__time)
end

function animation:invoke()
    if self.__duration < self.__time then return end

    for i, track in ipairs(self.__tracks) do
        local n = self.__nodes[i]
        local k = self.__keys[i]
        local p = self.__prev_value[i]
        local v = track:get_value(self.__time)
        local f = n[k]
        if type(f) == "function" then
            if p ~= v then
                self.__prev_value[i] = v
                f(n, unpack(v))
            end
        elseif f then
            if track.__agg then
                n[k] = track.__agg(n[k], v)
            else
                n[k] = v
            end
        end
    end
end

local player = {}
player.__index = player

function player:create()
    self.__animations = dict()
    self.__playing = nil
    self.__speed = 1
    self.__pause = 1
end

function player:animation(name, anime)
    anime = anime or animation.create()
    self.__animations[name] = anime
    return anime
end

function player:play(name)
    if name then
        local a = self.__animations[name]
        if not a then
            log.warn("Animation not found %s", name)
            return
        end
        a:reset()
        self.__playing = a
    else
        self.__pause = 1
    end
end

function player:speed(s)
    if not s then
        return self.__speed
    else
        self.__speed = s
        return self
    end
end

function player:pause()
    self.__pause = 0
    return self
end

function player:__update(dt)
    if not self.__playing then return end
    self.__playing:update(dt * self.__speed * self.__pause)
end

return animation
