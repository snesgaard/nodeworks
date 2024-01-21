local rng = love.math.random

local function random_slice()
    return spatial(rng(-10, 10), rng(-10, 0), rng(1, 10), rng(1, 10))
end

local function random_frame(dt)
    local quad = nil
    local slices = {
        foo=random_slice(),
        bar=random_slice(),
        baz=random_slice()
    }
    return Frame.create(quad, slices):set_dt(dt)
end

T("test_sprite_animator", function(T)
    stack.reset()

    local id = nw.ecs.id.weak()

    local sprite_state_map = {
        idle = Video.create(
            list(
                random_frame(1),
                random_frame(2),
                random_frame(3)
            )
        ):loop(),
        once = Video.create(
            list(
                random_frame(3.2),
                random_frame(3.4)
            )
        ):once(),
        loop = Video.create(
            list(
                random_frame(3.1),
                random_frame(3.3)
            )
        ):loop(),
    }

    stack.set(nw.component.sprite_state_map, id, sprite_state_map)

    nw.system.sprite_animation.play(id, "idle")

    local frame = nw.system.sprite_animation.get_frame(id)
    T:assert(frame == sprite_state_map.idle.frames[1])

    nw.system.time.clock.update(1.5)

    local frame = nw.system.sprite_animation.get_frame(id)
    T:assert(frame == sprite_state_map.idle.frames[2])

    nw.system.time.clock.update(2)

    local frame = nw.system.sprite_animation.get_frame(id)
    T:assert(frame == sprite_state_map.idle.frames[3])

    local slices, slice_data = nw.system.sprite_animation.get_slices_and_data(id)
    T:assert(slices)
    T:assert(slices == frame.slices)
    T:assert(slice_data == frame.slice_data)

    T("loop", function(T)
        nw.system.sprite_animation.play(id, "loop")
        nw.system.time.clock.update(7)

        T:assert(not nw.system.sprite_animation.is_done(id))
        T:assert(
            nw.system.sprite_animation.get_frame(id) == 
            sprite_state_map.loop.frames[1]
        )

        nw.system.sprite_animation.play(id, "once")
        nw.system.time.clock.update(14)

        T:assert(nw.system.sprite_animation.is_done(id))
        T:assert(
            nw.system.sprite_animation.get_frame(id) == 
            sprite_state_map.once.frames[2]
        )
    end)
end)
