local clock = {id = "__clock__"}

function clock.spin()
    for _, dt in event.view("update") do clock.update(dt) end
end

function clock.update(dt)
    stack.set(nw.component.time, clock.id, clock.get() + dt)
end

function clock.get()
    return stack.ensure(nw.component.time, clock.id)
end

function clock.set(time)
    stack.set(nw.component.time, clock.id, time)
end

local timer = {}

function timer.has(id)
    return stack.get(nw.component.timer, id) ~= nil
end

function timer.is_done(id)
    local time, duration = timer.get(id)
    if not time then return true end
    return duration <= time
end

function timer.get(id)
    local t = stack.get(nw.component.timer, id)
    if not t then return end
    return clock.get() - t.time, t.duration
end

function timer.spin()
    local kill_these = list()

    for id, _ in stack.view_table(nw.component.die_on_timer_done) do
        if timer.is_done(id) == true then table.insert(kill_these, id) end
    end

    for _, id in ipairs(kill_these) do
        stack.destroy(id)
    end
end

local system = {
    clock = clock,
    timer = timer
}

function system.spin()
    clock.spin()
    timer.spin()
end

return system