local math = require "math"
local List = require "list"

local Listener = {}
Listener.__index = Listener

function Listener.create(event, callback)
    callback = callback or function() end
    local this = {
        event = event, callback = callback, count = 0, limit = math.huge
    }
    return setmetatable(this, Listener)
end

function Listener:take(limit)
    self.limit = limit
    return self
end

function Listener:called()
    return self.count > 0
end

function Listener:__call(...)
    self.count = self.count + 1
    -- HACK ENSURE THAT OUTER CALLBACK LOOP DOES NOT SKIP DUE TO THIS REMOVAL
    if self.count >= self.limit then self:remove() end
    return self.callback(...)
end

function Listener:remove()
    self.event:remove(self)
end

local Event = {}
Event.__index = Event

function Event.create()
    -- NOTE Make event lockable to subscribers and
    return setmetatable({listeners = {}, queue = List.create()}, Event)
end

function Event:__call(...)
    self.__locked = true
    for cb, active in pairs(self.listeners) do
        if cb(...) then
            self:remove(cb)
        end
    end
    for l, _ in pairs(self.queue) do
        self.listeners[l] = true
    end
    self.queue = {}
    self.__locked = false
end

function Event:size()
    return Dictionary.create(self.listeners):values():size()
end

function Event:listen(callback)
    local listener = Listener.create(self, callback)
    if not self.__locked then
        self.listeners[listener] = true
    else
        self.queue[listener] = true
    end
    return listener
end

function Event:remove(listener)
    self.listeners[listener] = nil
    self.queue[listener] = nil
end

local __wait_listeners = {}
local __wait_clean = {}

function Event.purge(co)
    local listeners = __wait_listeners[co]

    if not listeners then
        return
    end

    for e, l in pairs(listeners) do
        if istype(Event, e) then
            l:remove()
        -- If it is a tween, simply remove the finish field
        else
            e.finishField = nil
        end
    end

    if __wait_clean[co] then
        __wait_clean[co]()
    end
    __wait_listeners[co] = nil
    __wait_clean[co] = nil
end

function Event.on_purge(cleanup)
    local co = coroutine.running()
    __wait_clean[co] = cleanup
end

function Event.wait(events)
    if #events == 0 then
        return
    end
    local co = coroutine.running()
    local listeners = {}

    local function continuation(e, ...)
        local args = {event = e, ...}
        Event.purge(co)
        local status, msg
        if #events > 1 then
            status, msg = coroutine.resume(co, args)
        else
            status, msg = coroutine.resume(co, ...)
        end
        if not status then
            log.error(msg)
        end
    end

    for _, e in ipairs(events) do
        local function callback(...)
            continuation(e, ...)
        end
        -- Determine whether is a an event
        if e.listen then
            listeners[e] = e:listen(callback)
        -- or a tween
        elseif e.finish then
            listeners[e] = e:finish(callback)
        end
    end

    -- Store in case we want to purge
    __wait_listeners[co] = listeners
    __wait_clean[co] = events.cleanup
    return coroutine.yield()
end

return Event
