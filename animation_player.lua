local function search_time(time)
    return function(t)
        return time <= t
    end
end

local track = {}
track.__index = track

function track.create(values, times, opt)
    opt = opt or {}
    local this = {
        __values = values,
        __times = list(unpack(times)),
        __agg = opt.agg,
        __ease = opt.ease,
        __size = math.min(#values, #times),
        __time = 0
    }
    return setmetatable(this, track)
end

function track:ease(ease)
    if ease then
        self.__ease = ease
        return self
    else
        return self.__ease
    end
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

function track:search_frame(time)
    for i = 0, #self.__times do
        local t1 = self.__times[i]
        local t2 = self.__times[i + 1]
        if (not t2 or time < t2) and (not t1 or t1 <= time) then
            return math.max(i, 1)
        end
    end

    return self.__size
end

function track:get_value(time)
    if self.__size <= 0 then return end
    time = time or self.__time

    local frame = self:search_frame(time)

    if not self.__ease then
        local v1 = self:get_frame(frame)
        return v1
    else
        local v1, t1 = self:get_frame(frame)
        local v2, t2 = self:get_frame(frame + 1)
        if not v1 then
            return v2
        elseif not v2 then
            return v1
        end
        local d = t2 - t1
        local c = v2 - v1
        local time = math.clamp(time, t1, t2)
        local t = time - t1
        return self.__ease(t, v1, c, d)
    end
end

function track:update(dt)
    self.__time = self.__time + dt
end

local animation = {}
animation.__index = animation

function animation.create()
    local self = {}
    self.__tracks = {}
    self.__paths = {}
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

function animation:duration(d)
    if d then
        self.__duration = d
        return self
    else
        return self.__duration
    end
end

function animation:reset()
    self.__time = 0
end

function animation:track(path, ...)
    self.__tracks[#self.__tracks + 1] = track.create(...)
    self.__paths[#self.__paths + 1] = string.pathsplit(path)
    return self
end

function animation:bind(master)
    local function bind_path(path)
        local node = master
        for i = 1, #path - 1 do
            node = node[path[i]]
            if not node then
                log.warn("path undefined %s", tostring(path))
                return
            end
        end
        return node, path[#path]
    end

    for i, path in ipairs(self.__paths) do
        self.__nodes[i], self.__keys[i] = bind_path(path)
    end
end

function animation:invoke(time)
    if self.__duration < time then return end

    local function invoke_track(i, track)
        local n = self.__nodes[i]
        local k = self.__keys[i]
        if not n or not k then
            return
        end
        local p = self.__prev_value[i]
        local v = track:get_value(time)
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

    for i, track in ipairs(self.__tracks) do
        invoke_track(i, track)
    end
end

local player = {}
player.__index = player

function player:create()
    self.__animations = dict()
    self.__playing = nil
    self.__speed = 1
    self.__pause = 1
    self.__time = 0
end

function player:on_adopted()
    self:bind()
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
        self.__playing_name = name
        self.__time = 0
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

function player:set_time(time)
    return player:update(time - self.__time)
end

function player:pause()
    self.__pause = 0
    return self
end

function player:bind()
    if self.__parent then
        for key, anime in pairs(self.__animations) do
            anime:bind(self)
        end
    end
end

function player:__update(dt)
    if not self.__playing then return end

    dt = dt * self.__speed * self.__pause

    self.__time = self.__time + dt

    if self.__playing.__duration < self.__time and self.__playing.__loop then
        event(self, "loop", self.__playing_name)
        return self:update(-self.__duration)
    elseif self.__playing.__duration < self.__time then
        self.__playing:invoke(self.__playing.__duration)
        event:invoke(self, "done", self.__playing_name)
        self.__playing = nil
        return
    end

    self.__playing:invoke(self.__time)
end

return player
