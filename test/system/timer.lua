local stack = nw.ecs.stack
local timer = nw.system.timer
local event = nw.system.event

T("test_timer", function(T)
    local id = "yes"

    local was_called = {}
    
    stack.set(nw.component.timer, id, 2)
    stack.set(nw.component.on_timer_done, id, function() was_called.yes = true end)

    timer.update(1)
    T:assert(not was_called.yes)
    T:assert(not stack.get(nw.component.is_done, id))

    timer.update(2)
    T:assert(stack.get(nw.component.is_done, id))
    T:assert(was_called.yes)
end)