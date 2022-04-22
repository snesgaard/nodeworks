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
    local next_event = self:process(event)
    if not next_event then return self end

    for _, child in ipairs(self.children) do child:emit(next_event) end

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

    for _, child in ipairs(self.children) do child:clear_chain() end
end

function observable:clear() end

local collect = setmetatable({}, observable)
collect.__index = collect


function collect.create()
    local obs = observable.create()
    obs.data = list()
    return setmetatable(obs, collect)
end

function collect:process(event)
    table.insert(self.data, event)
    return event
end

function collect:pop()
    local d = self.data
    self.data = list()
    return d
end

function collect:peek() return self.data end

local filter = setmetatable({}, observable)
filter.__index = filter

function filter.create(func)
    local obs = observable.create()
    obs.func = func
    return setmetatable(obs, filter)
end

function filter:process(event)
    if self.func(unpack(event)) then return event end
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

function reduce:get() return self.value end

-- Final methods for collection
local chain_methods = {
    collect = collect,
    filter = filter,
    reduce = reduce
}

for name, chain in pairs(chain_methods) do
    observable[name] = function(self, ...)
        local c = chain.create(...)
        c:add_parent(self)
        self:add_child(c)
        return c
    end
end

return {
    collect=collect.create
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
