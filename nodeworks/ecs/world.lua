local nw = require "nodeworks"
local debug = require  "debug"

local weak_table = {__mode = "v"}

local CONSTANTS = {EMPTY_LIST = {}, TERMINATE = {}}

local context = {}
context.__index = context

function context.create(world, system, ...)
    return setmetatable(
        {
            co = coroutine.create(
                function(...)
                    system(...)
                    coroutine.yield(CONSTANTS.TERMINATE)
                end
            ),
            args = {...},
            system = system,
            world = world,
            observers = setmetatable({}, weak_table), -- Needs to be weakly reference
            alive = true
        },
        context
    )
end

function context:__call(...) return self.world:ensure(...) end

function context:resume()
    if self.co then
        local status, msg = coroutine.resume(self.co, self, unpack(self.args))
        if not status then
            print(debug.traceback(self.co))
            error(msg)
        elseif msg == CONSTANTS.TERMINATE then
            self.co = nil
            self.alive = false
        end
    end

    return self
end

function context:is_alive() return self.alive end

function context:listen(event)
    self.observers[event] = self.observers[event] or nw.ecs.promise.observable()
    return self.observers[event]
end

function context:emit(...)
    self.world:emit(...)
    return self
end

function context:parse_single_event(event_key, event_data)
    local obs = self.observers[event_key]
    if not obs or event_data.consumed then return false end
    obs:emit(event_data)
    return true
end

function context:clear()
    for _, obs in pairs(self.observers) do obs:clear_chain() end
    return self
end

function context:kill()
    self.alive = false
    return self:resume()
end

function context:yield(...)
    if self.alive then return coroutine.yield(...) end
end

function context:kill_all_but_this()
    local world = self.world

    for _, ctx in ipairs(world.context) do
        if ctx ~= self then ctx:kill() end
    end

    world:remove_dead_systems()

    return self
end

local world = {}
world.__index = world

function world.create()
    return setmetatable(
        {
            events = list(),
            context = {},
            queue = event_queue()
        },
        world
    )
end


function world:push(system, ...)
    local ctx = context.create(self, system, ...)
    table.insert(self.context, ctx)
    return ctx:resume()
end

function world:emit(event_key, ...)
    table.insert(self.events, {key = event_key, data = {...}})
    return self
end

function world:pop_events()
    local e = self.events
    if #e <= 0 then return e end
    self.events = list()
    return e
end

function world:has_events()
    for _, _ in pairs(self.events) do return true end
    return false
end

function world:remove_dead_systems()
    for i = #self.context, 1, -1 do
        local ctx = self.context[i]
        if not ctx:is_alive() then table.remove(self.context, i) end
    end
end

function world:spin()
    local events = self:pop_events()

    while not events:empty() do
        local event = events:head()

        for _, ctx in ipairs(self.context) do
            if ctx:parse_single_event(event.key, event.data) then
                ctx:resume()
                ctx:clear()
            end
        end

        local next_events = self:pop_events()
        events = events:body()
        if #next_events > 0 then events = next_events + events:body() end
    end

    self:remove_dead_systems()

    return self
end

function world:find(system)
    local ctx = List.filter(
        self.context, function(c) return c.system == system end
    )
    return ctx:unpack()
end

function world:ensure(system, ...)
    local ctx = world:find(system)
    if ctx then return ctx end
    return self:push(system, ...)
end

world.Context = context

return world
