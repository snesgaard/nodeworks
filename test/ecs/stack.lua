local stack = nw.ecs.stack

local component = {}

function component.foo(v) return v or 0 end

T("test_stack", function(T)
    stack.reset()

    local id = "yes"

    T:assert(stack.size() == 1)
    stack.push()
    T:assert(stack.size() == 2)
    stack.pop()
    T:assert(stack.size() == 1)
    stack.pop()
    T:assert(stack.size() == 1)

    stack():set(component.foo, id)
    T:assert(stack():get(component.foo, id) == 0)

    local world_former = stack.current()
    stack.push()
    local world_next = stack.current()
    T:assert(world_former ~= world_next)

    T:assert(stack.size() == 2)
    stack():set(component.foo, id, 22)
    T:assert(stack.get(component.foo, id) == 22)

    stack.pop()
    T:assert(stack.size() == 1)
    T:assert(stack():get(component.foo, id) == 0)
end)