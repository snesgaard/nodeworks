local context = {}
context.__index = context

function context.create(world)
    return setmetatable(
        {
            world=world,
            alive=true
        },
        context
    )
end

function context:read_event(event_key)
    return self.world:read_event(self, event_key)
end

function context:visit_event(event_key, func)
    local events = self.world:read_event(self, event_key)
    for _, event in ipairs(events) do
        if func(self, event:unpack()) then event:consume() end
    end
end

local event = {}
event.__index = event

function event.create(...)
    return setmetatable({...}, event)
end

function event:observe(system)
    local seen_before = self[system]
    self[system] = true
    return seen_before
end

function event:consume() self.consumed = true end

function event:unpack() return unpack(self) end

local CONSTANTS = {EMPTY_LIST = {}, TERMINATE = {}}

local world = {}
world.__index = world

local function system_wrapper(system, ...)
    system(...)
    coroutine.yield(CONSTANTS.TERMINATE)
end

function world:emit(event_key, ...)
    self.events[event_key] = self.events[event_key] or {}
    table.insert(self.events[event_key], event.create(...))
    return self
end

function world:fetch_context(system) return self.context[system] end

function world:has_events()
    for key, queue in pairs(self.events) do
        if #queue > 0  then return true end
    end
    return false
end

function world:read_event(reader, key)
    local event_queue = self.events[key] or CONSTANTS.EMPTY_LIST

    for i = #event_queue, 1, -1 do
        local e = event_queue[i]
        if e.consumed or e:observe(reader) then table.remove(event_queue, i) end
    end

    return event_queue
end

function world:push(system, ...)
    table.insert(self.systems, system)
    self.args[system] = {...}
    self.context[system] = context.create(self)
    self.coroutines[system] = coroutine.create(function(...)
        return system_wrapper(system, ...)
    end)

    return self
end

function world:resolve()
    while self:has_events() do
        for _, system in ipairs(self.systems) do
            local co = self.coroutines[system]
            local ctx = self.context[system]
            local args = self.args[system]
            if co and ctx and args then
                local ret, msg = coroutine.resume(co, ctx, unpack(args))

                if ret then
                    if msg == CONSTANTS.TERMINATE then
                        self.coroutines[system] = nil
                        self.context[system] = nil
                        self.args[system] = nil
                    end
                else
                    error(msg)
                end
            end
        end

        -- Add self as "reader" for event. This is to make sure that unobserved
        -- events still get removed eventually
        for key, _ in pairs(self.events) do self:read_event(self, key) end
    end

    for i = #self.systems, 1, -1 do
        local system = self.systems[i]
        local co = self.coroutines[system]
        local ctx = self.context[system]
        local args = self.args[system]
        if not co or not ctx or not args then
            table.remove(self.systems, i)
            self.coroutines[system] = nil
            self.context[system] = nil
            self.args[system] = nil
        end
    end

    return self
end

return function()
    return setmetatable(
        {
            context = {},
            systems = list(),
            coroutines = {},
            args = {},
            events = {}
        },
        world
    )
end
