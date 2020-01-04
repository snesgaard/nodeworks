local default_group = {}

local function insert_group(handle, group)
    group = group or default_group
    local index = #group + 1
    group[handle] = index
    group[index] = handle
    handle._group = group
end

local function remove_group(handle)
    local group = handle._group
    if not group then return end

    local index = group[handle]
    group[handle] = nil
    for i = index, #group do
        local g = group[i + 1]
        group[i] = g
        if g then group[g] = i end
    end
    handle._group = nil
end

local function shallow_copy(table)
    local copy = {}
    for key, value in pairs(table) do copy[key] = value end
    return copy
end

local TweenHandle = {}
TweenHandle.__index = TweenHandle

local function pack_to_from(_from, _to, _change, _dst, _set, from, to, ...)
    if not from or not to then return end

    local index = #_from + 1

    _from[index] = {}
    _to[index] = to
    _change[index] = {}
    _dst[index] = {}
    _set[index] = from

    for k, t in pairs(to) do
        local f = from[k]
        if t then
            _change[index][k] = t - f
            _from[index][k] = f
        end
    end

    return pack_to_from(_from, _to, _change, _dst, _set, ...)
end

function TweenHandle.create(duration, ...)
    local this = setmetatable(
        {
            _from = {}, _to = {},
            _duration = duration,
            _time = 0,
            _group = default_group,
            _delay = 0,
            _change = {},
            _dst = {},
            _set = {},
            _ease = ease.linear,
        },
        TweenHandle
    )

    pack_to_from(
        this._from, this._to, this._change, this._dst, this._set,
        ...
    )
    insert_group(this)
    return this
end

function TweenHandle:group(group)
    remove_group(self)
    insert_group(self, group)
    self._group = group
    return self
end

function TweenHandle:remove()
    remove_group(self)
    return self
end

function TweenHandle:delay(delay)
    self._delay = delay
    return self
end


function TweenHandle:set(set, ...)
    local setters = {set, ...}
    if #setters == 1 and type(set) == "function" then
        self._set = set
    else
        for i, s in ipairs(self._set) do
            self._set[i] = setters[i] or s
        end
    end
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

function TweenHandle:call(f)
    self._call = f
    return self
end

local tween = {}

local function update_tween(dt, tween)
    tween._delay = math.max(0, tween._delay - dt)

    if tween._delay > 0 then return false end

    tween._time = math.min(tween._duration, tween._time + dt)
    local is_done = tween._time >= tween._duration

    -- Perform the actual interpolation
    for i = 1, #tween._from do
        local from = tween._from[i]
        local change = tween._change[i]
        local dst = tween._dst[i]
        for k, f in pairs(from) do
            local c = change[k] or 0
            dst[k] = tween._ease(tween._time, f, c, tween._duration)
        end
    end

    if type(tween._set) == "function" then
        tween._set(unpack(tween._dst))
    elseif type(tween._set) == "table" then
        for i, set in ipairs(tween._set) do
            local dst = tween._dst[i]
            if type(set) == "function" then
                set(dst)
            elseif type(set) == "table" then
                for k, v in pairs(dst) do set[k] = v end
            end
        end
    end

    if tween._call then
        tween._call(tween._dst)
    end

    if is_done then
        if tween._after then tween._after(unpack(tween._dst)) end

        event(tween, "finish", unpack(tween._dst))
    end

    return is_done
end

function tween.update(dt, group)
    group = group or default_group
    local update_group = {unpack(group)}
    for i = 1, #update_group do
        local t = update_group[i]
        if t and update_tween(dt, t) then
            remove_group(t)
            i = i - 1
        end
    end
end

function tween:__call(duration, ...)

    if duration then return TweenHandle.create(duration, ...) end
end

return setmetatable(tween, tween)
