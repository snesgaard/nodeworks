---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local event_types = {}

---@param v number
---@return number
function event_types.update(v) return v or 0 end

---@param s string
---@param i integer
function event_types.foobar(s, i)
    return {
        string = s,
        integer = i
    }
end

T("event", function(T)
    -- Clear the stack
    nw.ecs.stack.clear()

    T("swap", function()
        -- There should be no initial events
        T:assert(not nw.system.event.swap())
        -- Event a single event
        nw.system.event.emit(event_types.update, 42)
        -- Swap, it should now report having events
        T:assert(nw.system.event.swap())
        -- Check that one update event exists
        local e = nw.system.event.get(event_types.update)
        T:assert(#e == 1)
        T:assert(nw.list.head(e) == 42)
        -- Swap again, no events should remain
        T:assert(not nw.system.event.swap())
        -- Check that no update event is present
        T:assert(#nw.system.event.get(event_types.update) == 0)
    end)

    T("view", function()
        local passed = false
        local s = "yes"
        local i = 60
        nw.system.event.emit(event_types.foobar, s, i)
        nw.system.event.swap()

        for _, e in nw.system.event.view(event_types.foobar) do
            passed = true
            T:assert(e.string == s)
            T:assert(e.integer == i)
        end

        T:assert(passed)
    end)
end)