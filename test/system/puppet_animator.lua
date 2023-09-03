local pa = nw.system.puppet_animator
local clock = nw.system.time.clock

local idle = {
    {dt = 1},
    {dt = 2},
    {dt = 3}
}
local hit = {
    {dt = 1},
    {dt = 2}
}

local state_map = {
    idle = Video.create(idle):loop(),
    hit = Video.create(hit):once()
}

T("puppet_animator", function(T)
    stack.reset()
    
    local id = {}
    stack.set(nw.component.puppet_state_map, id, state_map)
    stack.set(nw.component.puppet_state, id, "idle")

    T("is_done", function(T)
        T:assert(not pa.is_done(id))
        clock.update(10)
        T:assert(not pa.is_done(id))

        stack.set(nw.component.puppet_state, id, "hit")

        T:assert(not pa.is_done(id))
        clock.update(10)
        T:assert(pa.is_done(id))
    end)

    T("ensure", function(T)
        T:assert(not pa.ensure(id, "idle"))
        T:assert(pa.ensure(id, "hit"))
        T:assert(not pa.ensure(id, "hit"))
    end)

    T("update", function(T)
        T:assert(not stack.has(nw.component.frame, id))
        pa.update()
        T:assert(stack.has(nw.component.frame, id))
        T:assert(stack.get(nw.component.frame, id) == idle[1])

        clock.update(1.5)
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == idle[2])

        stack.set(nw.component.puppet_state, id, "hit")
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == hit[1])

        clock.update(1.5)
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == hit[2])
        
        T("without_map", function(T)
            stack.remove(nw.component.puppet_state_map, id)
            pa.update()
        end)
    end)
end)