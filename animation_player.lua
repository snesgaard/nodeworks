local track = {}
track.__index = track

function track.create(times, values, opt)
    opt = opt or {}

    print(times, values)
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
        _tracks = {},
        _paths = {},
        _fullpaths = {},
        _keys = {},
        _ids = {},
        _duration = 0
    }
    return setmetatable(this, animation)
end

animation.duration = attribute("__duration")

function animation:init(graph, subgraph)
    local _paths = {}
    for index, p in ipairs(self._paths) do
        _paths[index] = string.join(subgraph, p)
    end
    return {paths = _paths, graph = graph}
end

function animation:track(full_path, ...)
    local track = track.create(...)
    local index = #self._tracks + 1
    local parts = string.split(full_path, ":")

    if #parts ~= 2 then
        error(string.format("Invalid path %s", full_path))
    end

    self._tracks[index] = track
    self._fullpaths[index] = full_path
    self._paths[index] = parts[1]
    self._keys[index] = parts[2]
    return self
end

function animation:read(fullpath)
    local i = self._fullpaths:argfind(fullpath)
    if i then
        return self._tracks[i]
    end
end

function animation.reset_loop(track_states)
    for _, state in pairs(track_states) do
        state.prev_value = nil
    end
end

local FINISH = 1

function animation:_find_node(graph, paths, index)
    local path = paths[index]
    local key = self._keys[index]
    return graph:find(path), key, self._tracks[index]
end

function animation:update(time, track_states)
    if time > self:duration() then
        -- If finished do the final updates
        for index = 1, #self._tracks do
            local n, k, t = self:_find_node(
                track_states.graph, track_states.paths, index
            )
            if n then
                track_states[index] = t:update(
                    self:duration(), track_states[index], n, k
                )
            end
        end

        return track_states, FINISH
    end

    for index = 1, #self._tracks do
        local n, k, t = self:_find_node(
            track_states.graph, track_states.paths, index
        )
        if n then
            track_states[index] = t:update(
                time, track_states[index], n, k
            )
        end
    end

    return track_states
end

local player = {}
player.__index = player

function player:create()
    local this = {
        _animations = dict(),
        _animation_state = nil,
        _play = 1,
        _speed = 1,
        _time = 0
    }
    return setmetatable(this, player)
end

function player:clone()
    local other = Node.create(player)
    other._animations = self._animations
    return other
end

player.speed = attribute("_speed")

function player:animation(name)
    if not self._animations[name] then
        self._animations[name] = animation.create()
    end
    return self._animations[name]
end

local function get_offset(frames)
    local function get_origin(f)
        if not f.slices.origin then
            return Vec2(0, 0)
        else
            return f.slices.origin:centerbottom()
        end
    end

    return frames:map(function(f)
        local o = get_origin(f)
        return f.offset - o
    end)
end

function player:from_atlas(atlas, key, alias)
    local frames = atlas:get_animation(key)

    if not frames then
        error(string.format("Animation <%s> undefined", key))
    end

    local anime = self:animation(alias or key)

    local offset = get_offset(frames)
    local images = frames:map(function(f) return f.image end)
    local quads = frames:map(function(f) return f.quad end)

    local time_deltas = frames:map(function(f) return f.dt end)
    local times = time_deltas:scan(function(a, b)
        return a + b
    end, 0)
    local duration = times[#times]
    times[#times] = nil

    anime
        :track("texture:texture", times, images)
        :track("texture:quad", times, quads)
        :track("texture:ox", times, offset:map(function(o) return -o.x end))
        :track("texture:oy", times, offset:map(function(o) return -o.y end))
        :duration(duration)

    return anime
end

function player:clear(name)
    self._animations[name] = nil
    return self
end

function player:play(name, graph, subgraph, loop)
    subgraph = subgraph or ""
    if not name then
        self._play = true
        return
    end

    local anime = self._animations[name]
    if not anime then
        log.warn("Animation %s does not exist", name)
        return
    end
    self._current_animation = anime
    self._animation_state = anime:init(graph, subgraph)
    self._time = 0
    self._loop = loop
end

function player:pause()
    self._play = false
    return self
end

function player:reset()
    self._time = 0
    return self
end


function player:update(dt)
    if not self._play then
        return
    end

    self._time = self._time + (dt * self._speed)

    if self._current_animation then
        local code = nil
        self._animation_state, code = self._current_animation:update(
            self._time, self._animation_state
        )

        if code == FINISH then
            if not self._loop then
                self._play = false
                event(self, "finish")
            else
                event(self, "loop")
                animation.reset_loop(self._animation_state)
                return self:update(dt - self._current_animation:duration())
            end
        end
    end
end

return function(...)
    return player.create(...)
end
