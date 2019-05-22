local ease = require "easing"

local default_group = {}

local function insert_group(handle, group)
    group = group or default_group
    local index = #group + 1
    group[handle] = index
    group[index] = handle
end

local function remove_group(handle)
    local group = handle._group
    if not group then return end

    local index = group[handle]
    group[handle] = nil
    for i = index, #group do
        group[i] = group[i + 1]
    end
end

local function shallow_copy(table)
    local copy = {}
    for key, value in pairs(table) do copy[key] = value end
    return copy
end

local TweenHandle = {}
TweenHandle.__index = TweenHandle

function TweenHandle.create(from, to, duration)
    local this = setmetatable(
        {
            _from = from, _to = to,
            _duration = duration,
            _time = 0,
            _group = default_group,
            _delay = 0,
            _dst = {},
            _ease = ease.linear,
        },
        TweenHandle
    )
    this._change = {}
    for k, f in pairs(this._from) do
        local t = this._to[k] or f
        this._change[k] = t - f
    end
    insert_group(this)
    return this
end

function TweenHandle:group(group)
    remove_group(self)
    insert_group(self, group)
    self._group = group
    return self
end

function TweenHandle:delay(delay)
    self._delay = delay
    return self
end

function TweenHandle:set(set)
    self._set = set
    return self
end

function TweenHandle:ease(ease)
    self._ease = ease or ease.linear
    return self
end

function TweenHandle:dst()
    self._dst = dst
    return self
end

function TweenHandle:after(after)
    self._after = after
    return self
end


local tween = {}

local function update_tween(dt, tween)
    tween._delay = math.max(0, tween._delay - dt)

    if tween._delay > 0 then return false end

    tween._time = math.min(tween._duration, tween._time + dt)
    local is_done = tween._time >= tween._duration

    -- Perform the actual interpolation
    for k, f in pairs(tween._from) do
        -- Should always be defined, just to be paranoid
        local c = tween._change[k] or 0
        tween._dst[k] = tween._ease(tween._time, f, c, tween._duration)
    end

    if tween._set then tween._set(tween._dst) end
    if is_done and tween._after then tween._after(tween._dst) end

    return is_done
end

function tween.update(dt, group)
    for i, t in ipairs(group or default_group) do
        if update_tween(dt, t) then remove_group(t) end
    end
end

function tween:__call(...)
    local function get_args(from, to, duration)
        if from and not to and not duration then
            if type(from) == "number" then
                return {}, {}, from
            else
                log.warn("Duration cannot be of type <%s>", type(from))
                return
            end
        elseif from and to and type(duration) == "number" then
            return from, to, duration
        else
            log.warn(
                "Invalid argument combination <%s> <%s> <%s>",
                type(from), type(to), type(duration)
            )
            return
        end
    end

    local from, to, duration = get_args(...)

    if duration then return TweenHandle.create(from, to, duration) end
end

return setmetatable(tween, tween)
