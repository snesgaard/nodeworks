---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local time = nw.system.time
local event = nw.system.event
local stack = nw.ecs.stack

local function spin()
    event.spin(time.spin)
end

T("time", function(T)
    -- Clear state
    nw.ecs.stack.clear()

    -- Check if clock works
    T("clock", function(T)
        T:assert(time.clock() == 0)
        event.emit(nw.event_type.update, 1)
        spin()
        T:assert(time.clock() == 1)
        event.emit(nw.event_type.update, 2)
        spin()
        T:assert(time.clock() == 3)
    end)

    -- Check timer
    T("timer", function(T)
        local id = "foo"
        local duration = 2.2
        -- No timer should return true
        T:assert(time.is_timer_done(id))
        -- Set timer, and we should no longer be done
        stack.set(nw.component.timer, id, duration)
        T:assert(not time.is_timer_done(id))
        -- Do half duration update, and we shoul dno longer be done
        event.emit(nw.event_type.update, duration / 2)
        spin()
        T:assert(not time.is_timer_done(id))
        -- Update the rest, and we should be done
        event.emit(nw.event_type.update, duration)
        spin()
        T:assert(time.is_timer_done(id))
    end)

    -- Check die on timer complete
    T("timer", function(T)
        local id = "foo"
        local duration = 3

        stack.set(nw.component.timer, id, duration)
        stack.set(nw.component.die_on_timer_done, id)

        event.emit(nw.event_type.update, duration * 2)
        spin()

        T:assert(stack.get(nw.component.timer, id) == nil)
    end)
end)