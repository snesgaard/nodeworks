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

function context:parse_events(events)
    local did_something = false

    -- Iterate all observers
    for event_key, obs in pairs(self.observers) do
        -- Check if there are any events avialable for this observer
        local e = events[event_key] or CONSTANTS.EMPTY_LIST
        -- Iterate the events
        for _, event in ipairs(e) do
            -- If event is not consumed then emit it into the observer
            -- Also set the did_something flag to signal something changed
            if not event.consumed then
                did_something = true
                obs:emit(event)
            end
        end
    end

    return did_something
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

local world = {}
world.__index = world

function world.create()
    return setmetatable(
        {
            events = {},
            context = {},
        },
        world
    )
end

function world:push(system, ...)
    local ctx = context.create(self, system, ...):resume()
    table.insert(self.context, ctx)
end

function world:emit(event_key, ...)
    self.events[event_key] = self.events[event_key] or list()
    table.insert(self.events[event_key], {...})
    return self
end

function world:pop_events()
    local e = self.events
    self.events = {}
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
    while self:has_events() do
        local events = self:pop_events()

        for _, ctx in ipairs(self.context) do
            if ctx:is_alive() and ctx:parse_events(events) then
                ctx:resume()
                ctx:clear()
            end
        end
    end

    self:remove_dead_systems()

    return self
end

return world.create
