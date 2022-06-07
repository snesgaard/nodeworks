local weak_table = {__mode = "v"}

local observable = {}
observable.__index = observable

function observable.create(operator, ...)
    return setmetatable(
        {
            operator=operator,
            args={...},
            children=setmetatable({}, weak_table), -- This needs to be a weak reference table
            parents={}
        },
        observable
    )
end

function observable:process(event) return event end

function observable:emit(event)
    if type(event) ~= "table" then
        errorf("Event must be of type table, but was %s", type(event))
    end

    local next_event = self:process(event)
    if not next_event then return self end

    -- NOTE(SNJE): pairs might not respect order of adding. Is necessary sadly
    -- as when gc claims a child, it's entry is eimply left as nil, which
    -- breaks ipairs.
    --
    -- Also note that this is only a problem for passive callbacks like foreach.
    -- For sideffect-less observables the ordering doesn't matter.
    for _, child in pairs(self.children) do child:emit(next_event) end

    return self
end

function observable:add_child(child)
    table.insert(self.children, child)
    return self
end

function observable:add_parent(parent)
    table.insert(self.parents, parent)
    return self
end

function observable:clear_chain()
    self:clear()

    for _, child in pairs(self.children) do child:clear_chain() end
end

function observable:clear() end

local collect = setmetatable({}, observable)
collect.__index = collect


function collect.create(retain)
    local obs = observable.create()
    obs.data = list()
    obs.retain = retain
    return setmetatable(obs, collect)
end

function collect:process(event)
    if #event == 1 then
        table.insert(self.data, unpack(event))
    else
        table.insert(self.data, event)
    end
    return event
end

function collect:pop()
    local d = self.data
    self.data = list()
    return d
end

function collect:peek() return self.data end

function collect:clear() if not self.retain then self:pop() end end

local filter = setmetatable({}, observable)
filter.__index = filter

function filter.create(func)
    local obs = observable.create()
    obs.func = func
    return setmetatable(obs, filter)
end

function filter:process(event)
    local func = self.func or identity
    if func(unpack(event)) then return event end
end

local reduce = setmetatable({}, observable)
reduce.__index = reduce

function reduce.create(func, initial_value)
    local obs = observable.create()
    obs.func = func
    obs.initial_value = initial_value
    obs.value = initial_value
    return setmetatable(obs, reduce)
end

function reduce:process(event)
    self.value = self.func(self.value, unpack(event))
end

function reduce:peek() return self.value end

function reduce:reset()
    self.value = self.initial_value
    return self
end

local consume = setmetatable({}, observable)
consume.__index = consume

function consume.create()
    local obs = observable.create()
    return setmetatable(obs, consume)
end

function consume:process(event)
    event.consumed = true
    return event
end

local map = setmetatable({}, observable)
map.__index = map

function map.create(func)
    local obs = observable.create()
    obs.func = func
    return setmetatable(obs, map)
end

function map:process(event) return {self.func(unpack(event))} end

local latest = setmetatable({}, observable)
latest.__index = latest

function latest.create(init)
    local obs = observable.create()
    obs.latest_event = init
    return setmetatable(obs, latest)
end

function latest:process(event)
    self.latest_event = event
    return event
end

function latest:peek()
    if self.latest_event then return unpack(self.latest_event) end
end

function latest:pop()
    local le = self.latest_event
    if not le then return end
    self.latest_event = nil
    return unpack(le)
end

function latest:empty() return self:peek() == nil end

local foreach = setmetatable({}, observable)
foreach.__index = foreach

function foreach.create(func)
    local obs = observable.create()
    obs.func = func
    return setmetatable(obs, foreach)
end

function foreach:process(event)
    self.func(unpack(event))
    return event
end

-- Final methods for collection
local chain_methods = {
    collect = collect,
    filter = filter,
    reduce = reduce,
    map = map,
    latest = latest,
    foreach = foreach,
    consume = consume,
}

for name, chain in pairs(chain_methods) do
    observable[name] = function(self, ...)
        local c = chain.create(...)
        c:add_parent(self)
        self:add_child(c)
        return c
    end
end

function merge(...)
    local obs = {...}
    local echo = observable.create()

    for _, o in ipairs(obs) do
        echo:add_parent(o)
        o:add_child(echo)
    end

    return echo
end

function observable:merge(...) return merge(self, ...) end

return {
    collect=collect.create,
    merge=merge,
    observable=observable.create
}

--[[
local update = ctx:listen("update"):collect()

local pressed = ctx:listen("keypressed")
    :filter(function(key) return key == "left" or key == "right")
    :map(function(key) return key == "left" and -1 or 1)

local released = ctx:listen("keyreleased")
    :filter(function(key) return key == "left" or key == "right")
    :map(function(key) return key == "left" and 1 or -1)

local horz_motion = observable.merge(pressed, released)
    :reduce(function(x, dx) return x + dx end, 0)

local say_boop = ctx:listen("keypressed")
    :filter(function(key) return key == "a" end)
    :consume()
    :map(function() return true end)
    :collect()

local gamestate = ctx:listen("gamestate"):latest()
local collisions = ctx:listen("collisions"):collect()

-- Implicit callback style? NO! MISSES THE POINT ABOUT ORDER AND CONTROL
-- Also only relevant for drawing and updating
local draw = ctx:listen("draw"):foreach(function() do_draw(ctx) end)
local second_draw = ctx:listen("draw"):foreach(function() do_draw(ctx) end)

ctx:emit("update", dt)
ctx:latch_emit()


update:pop():foreach()
]]--
