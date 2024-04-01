local path = (...):gsub("time", "")

---@module "component"
local component = require "nodeworks.component"
---@module "event_type"
local event_type = require "nodeworks.event_type"
---@module "nodeworks.system.event"
local event = require "nodeworks.system.event"
---@module "stack"
local stack = require "nodeworks.ecs.stack"

local system_id = "__system_time__"

local time = {}

function time.clock()
    return stack.ensure(component.time, system_id)
end

---@param dt number
function time.update(dt)
    local t = time.clock()
    local next_t = t + dt
    -- Update the clock
    stack.set(component.time, system_id, next_t)
    -- Populate timer init times, if not set
    for _, timer in stack.view_table(component.timer) do
        timer.time = timer.time or t
    end
    -- Check if anyone needs to die
    for id, _ in stack.view_table(component.die_on_timer_done) do
        if time.is_timer_done(id) then stack.destroy(id) end
    end
end

function time.is_timer_done(id)
    local timer = stack.get(component.timer, id)
    if timer == nil then return true end
    timer.time = timer.time or time.clock()
    return time.clock() - timer.time >= timer.duration
end

function time.spin()
    for _, dt in event.view(event_type.update) do
        time.update(dt)
    end
end

return time