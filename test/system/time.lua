local time = nw.system.time
local clock, timer = time.clock, time.timer

T("clock", function(T)
    stack.reset()
    T:assert(clock.get() == 0)
    
    T("set", function(T)
        clock.set(1337)
        T:assert(clock.get() == 1337)
    end)
    
    T("update", function(T)
        clock.set(1)
        clock.update(2)
        T:assert(clock.get() == 3)
    end)

    T("update/event", function(T)
        clock.set(1)
        event.emit("update", 2)
        event.spin()
        clock.spin()
        T:assert(clock.get() == 3)
    end)
end)

T("timer", function(T)
    stack.reset()
    clock.set(1)

    local id = {}
    local duration = 3
    stack.set(nw.component.timer, id, duration)

    T:assert(stack.get(nw.component.timer, id))
    T:assert(stack.get(nw.component.timer, id).duration == duration)
    T:assert(stack.get(nw.component.timer, id).time == clock.get())

    T:assert(not timer.is_done(id))

    T("done", function(T)
        clock.update(duration * 2)
        T:assert(timer.is_done(id))
        T:assert(timer.get(id) == clock.get() - 1)
    end)

    T("spin_and_delete", function(T)
        clock.update(duration * 2)

        timer.spin()
        T:assert(stack.get(nw.component.timer, id))

        stack.set(nw.component.die_on_timer_done, id)
        timer.spin()
        T:assert(not stack.get(nw.component.timer, id))
        T:assert(timer.is_done(id))
    end)

    T("has", function(T)
        T:assert(timer.has(id))
        T:assert(not timer.has({}))
    end)
end)