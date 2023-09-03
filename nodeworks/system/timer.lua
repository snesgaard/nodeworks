local nw = require "nodeworks"
local stack = nw.ecs.stack

local systemtimer = {}

function systemtimer.spin_once(id, timer, dt)
    if timer:done() then return end

    timer:update(dt)
    if not timer:done() then return end

    if stack.get(nw.component.die_on_timer_done, id) then
        stack.set(nw.component.should_be_destroyed, id)
    end

    local f = stack.get(nw.component.on_timer_done, id)
    if f then f(id) end

    stack.set(nw.component.is_done, id)
    -- TODO DECIDE on how to communicate donesss
end

function systemtimer.update(dt)
    for id, timer in stack.view_table(nw.component.timer) do
        systemtimer.spin_once(id, timer, dt)
    end
end

function systemtimer.spin()
    for _, dt in nw.system.event.view("update") do
        systemtimer.update(dt)
        -- TODO Decide on whehter to delete entities here
    end
end

function systemtimer.is_done(id)
    local timer = stack.get(nw.component.timer, id)
    if not timer then return true end
    return timer:done()
end

function systemtimer.get(id)
    local timer = stack.get(nw.component.timer, id)
    return timer
end

return systemtimer