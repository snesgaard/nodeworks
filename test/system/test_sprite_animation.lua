---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local pa = nw.system.sprite_animation
local time = nw.system.time

local stack = nw.ecs.stack

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
    idle = nw.video(idle):loop(),
    hit = nw.video(hit):once()
}

T("test_sprite_animator", function(T)
    stack.clear()
    
    local id = {}
    stack.set(nw.component.animation_map, id, state_map)
    nw.system.sprite_animation.play(id, "idle")

    T("is_done", function(T)
        T:assert(not pa.is_done(id))
        time.update(10)
        T:assert(not pa.is_done(id))

        nw.system.sprite_animation.play(id, "hit")

        T:assert(not pa.is_done(id))
        time.update(10)
        T:assert(pa.is_done(id))
    end)

    T("ensure", function(T)
        T:assert(not nw.system.sprite_animation.ensure(id, "idle"))
        T:assert(nw.system.sprite_animation.ensure(id, "hit"))
        T:assert(not nw.system.sprite_animation.ensure(id, "hit"))
    end)

    T("update", function(T)
        T:assert(stack.has(nw.component.frame, id))
        pa.update()
        T:assert(stack.has(nw.component.frame, id))
        T:assert(stack.get(nw.component.frame, id) == idle[1])

        time.update(1.5)
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == idle[2])

        nw.system.sprite_animation.play(id, "hit")
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == hit[1])

        time.update(1.5)
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == hit[2])
        
        T("without_map", function(T)
            stack.remove(nw.component.animation_map, id)
            pa.update()
        end)
    end)
end)