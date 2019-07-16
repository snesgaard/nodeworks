local track = {}
track.__index = track

function track.create(times, values, opt)
    opt = opt or {}

    local this = {
        __times = times,
        __values = values,
        __size = #times,
        __agg = opt.agg,
        __ease = opt.ease,
        __call = opt.call
    }

    return setmetatable(this, track)
end

function track:__init_state()
    return {time=-math.huge, frame=0, prev_value=nil}
end

function track:update(time, state, node, key)
    if self.__call then
        return self:__update_as_call(time, state, node, key)
    else
        return self:__update_as_value(time, state, node, key)
    end
end

function track:get_time(frame)
    if frame < 1 then
        return -math.huge, nil
    elseif self.__size < frame then
        return math.huge, nil
    else
        return self.__times[frame]
    end
end

function track:get_value(frame)
    return self.__values[frame]
end

function track:__update_as_value(time, state, node, key)
    state = state or self:__init_state()
    local prev_frame = state.frame
    local prev_time = state.time

    local dir = time > prev_time and 1 or -1
    local stop = dir > 0 and self.__size or 0

    local function find_next_frame()
        for f = prev_frame, stop, dir do
            if self:get_time(f) < time and time <= self:get_time(f + 1) then
                return f
            end
        end
    end

    local f = find_next_frame()

    local function call_value(value)
        local f = node[key]
        if type(f) == "function" then
            f(node, value)
        else
            if self.__agg then
                node[key] = self.__agg(node[key], value, state.prev_value)
            else
                node[key] = value
            end
        end
    end

    if 0 < f and f <= self.__size then
        if self.__ease and f ~= self.__size then
            local t1, t2 = self:get_time(f), self:get_time(f + 1)
            local v1, v2 = self:get_value(f), self:get_value(f + 1)
            local b = time - t1
            local d = t2 - t1
            local c = v2 - v1
            local v = self.__ease(b, v1, c, d)
            call_value(v)
            state.prev_value = v
        else
            local v = self:get_value(f)
            call_value(v)
            state.prev_value = v
        end
    end

    state.time = time
    state.frame = f
    return state
end

function track:__update_as_call(time, state, node, key)
    state = state or self:__init_state()
    local prev_frame = state.frame
    local prev_time = state.time

    local dir = time > prev_time and 1 or -1
    local stop = dir > 0 and self.__size or 0

    local function invoke(value)
        if not key then
            node(value)
        else
            node[key](value)
        end
    end

    state.time = time
    for f = prev_frame, stop, dir do
        local t = self:get_time(f)
        if prev_time < t and t <= time then
            invoke(self:get_value(f))
            state.frame = f
        end
    end
    return state
end

local animation = {}
animation.__index = animation

function animation.create()
    local this = {
        __tracks = {},
        __paths = {},
        __nodes = {},
        __keys = {},
        __duration = 0
    }
    return setmetatable(this, animation)
end

animation.duration = attribute("__duration")

function animation:track(path, ...)
    local track = track.create(...)
    local index = #self.__tracks + 1
    self.__tracks[index] = track
    self.__paths[index] = path
    return self
end

function animation:read(path)
    local i = self.__paths:argfind(path)
    if i then
        return self.__tracks[i]
    end
end

function animation.reset_loop(track_states)
    for _, state in pairs(track_states) do
        state.prev_value = nil
    end
end

local FINISH = 1
local LOOP = 2

function animation:update(time, track_states, exit_code)
    track_states = track_states or {}

    if time > self:duration() then
        -- If finished do the final updates
        for index, track in pairs(self.__tracks) do
            local path = self.__paths[index]
            local n, k = self.__nodes[index], self.__keys[index]
            if n then
                track_states[index] = track:update(
                    self:duration(), track_states[index], n, k
                )
            end
        end

        return track_states, FINISH
    end

    for index, track in pairs(self.__tracks) do
        local path = self.__paths[index]
        local n, k = self.__nodes[index], self.__keys[index]
        if n then
            track_states[index] = track:update(
                time, track_states[index], n, k
            )
        end
    end

    return track_states
end

function animation:link(master)
    local function bind_track(path, track)
        if type(path) ~= "string" then
            return path
        end
        local parts = string.pathsplit(path)
        local node = master
        for i = 1, #parts - 1 do
            node = node[parts[i]]
            if not node then
                log.warn("path %s could not be resolved", path)
                return
            end
        end
        local key = parts[#parts]
        return node, key
    end

    for index, track in pairs(self.__tracks) do
        local path = self.__paths[index]
        self.__nodes[index], self.__keys[index] = bind_track(path, track)
    end
end

local player = {}
player.__index = player

function player:create()
    self.__animations = dict()
    self.__animation_state = nil
    self.__play = 1
    self.__speed = 1
    self.__time = 0
end

function player:clone()
    local other = Node.create(player)
    other.__animations = self.__animations
    return other
end

player.speed = attribute("__speed")

function player:animation(name)
    if not self.__animations[name] then
        self.__animations[name] = animation.create()
    end
    return self.__animations[name]
end

function player:clear(name)
    self.__animations[name] = nil
    return self
end

function player:play(name, loop)
    if not name then
        self.__play = true
        return
    end

    local anime = self.__animations[name]
    if not anime then
        log.warn("Animation %s does not exist", anime)
        return
    end
    self.__current_animation = anime
    self.__time = 0
    self.__loop = loop
end

function player:pause()
    self.__play = false
    return self
end

function player:reset()
    self.__time = 0
    return self
end

function player:on_adopted()
    for _, anime in pairs(self.__animations) do
        anime:link(self)
    end
end

function player:__update(dt)
    if not self.__play then
        return
    end

    self.__time = self.__time + (dt * self.__speed)

    if self.__current_animation then
        local code = nil
        self.__animation_state, code = self.__current_animation:update(
            self.__time, self.__animation_state
        )

        if code == FINISH then
            if not self.__loop then
                self.__play = false
                event(self, "finish")
            else
                event(self, "loop")
                animation.reset_loop(self.__animation_state)
                return self:__update(dt - self.__current_animation:duration())
            end
        end
    end
end

return player
