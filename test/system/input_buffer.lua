local nw = require "nodeworks"
local input_buffer = nw.system.input_buffer
local T = nw.third.knife.test

local scene = {}

function scene.on_push(ctx)
    ctx.main = ctx:entity("buffer")
        :set(nw.component.input_buffer)
end

T("input_buffer", function(T)
    local world = nw.ecs.world{input_buffer}
    local ctx = world:push(scene):find(scene)
    ctx:handle_dirty()

    T("members", function(T)
        local pool = ctx.pools[input_buffer]
        -- Two single an input buffer is also pushed to the world singleton
        T:assert(#pool == 2)
    end)

    T("input_released", function(T)
        world("input_released", "foo")

        T:assert(input_buffer.peek.is_released(ctx.main, "foo"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_released(ctx.main, "foo"))
    end)

    T("input_pressed", function(T)
        world("input_pressed", "foo")

        T:assert(input_buffer.peek.is_pressed(ctx.main, "foo"))
        T:assert(not input_buffer.peek.is_pressed(ctx.main, "bar"))
        T:assert(not input_buffer.peek.is_released(ctx.main, "foo"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_pressed(ctx.main, "foo"))
        T:assert(not input_buffer.peek.is_pressed(ctx.main, "bar"))
        T:assert(not input_buffer.peek.is_released(ctx.main, "foo"))
    end)

    T("is_down", function(T)
        T:assert(not input_buffer.peek.is_down(ctx.main, "foo"))

        world("input_pressed", "foo")

        T:assert(input_buffer.peek.is_down(ctx.main, "foo"))
        T:assert(not input_buffer.peek.is_down(ctx.main, "bar"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(input_buffer.peek.is_down(ctx.main, "foo"))

        world("input_released", "foo")

        T:assert(not input_buffer.peek.is_down(ctx.main, "foo"))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_down(ctx.main, "foo"))

        world("input_pressed", "foo")

        T:assert(input_buffer.peek.is_down(ctx.main, "foo"))

        world("input_released", "foo")

        T:assert(not input_buffer.peek.is_down(ctx.main, "foo"))
    end)

    T("is_pressed_multi", function(T)
        local inputs = {"foo", "bar"}

        T:assert(not input_buffer.peek.is_pressed(ctx.main, inputs))

        for _, input in ipairs(inputs) do
            world("input_pressed", input)
        end

        T:assert(input_buffer.peek.is_pressed(ctx.main, inputs))

        world("update", input_buffer.MAX_AGE + 1)

        T:assert(not input_buffer.peek.is_pressed(ctx.main, inputs))
    end)

    T("is_pressed_delay", function(T)
        world("input_pressed", "foo")
        world("update", input_buffer.MAX_AGE + 1)
        world("input_pressed", "bar")

        T:assert(input_buffer.peek.is_pressed(ctx.main, "bar"))
        T:assert(not input_buffer.peek.is_pressed(ctx.main, "foo"))
        T:assert(input_buffer.peek.is_down(ctx.main, "foo"))

        T:assert(input_buffer.peek.is_pressed(ctx.main, {"foo", "bar"}))

        world("update", input_buffer.MAX_AGE / 2)

        T:assert(input_buffer.peek.is_pressed(ctx.main, {"foo", "bar"}))

        world("input_released", "foo")

        T:assert(input_buffer.peek.is_pressed(ctx.main, {"foo", "bar"}))
    end)

    T("is_pressed_pop", function(T)
        world("input_pressed", "foo")
        T:assert(input_buffer.is_pressed(ctx.main, "foo"))
        T:assert(not input_buffer.is_pressed(ctx.main, "foo"))

        world("input_pressed", "foo")
        world("update", input_buffer.MAX_AGE / 2)
        world("input_pressed", "foo")
        T:assert(input_buffer.is_pressed(ctx.main, "foo"))
        T:assert(input_buffer.is_pressed(ctx.main, "foo"))
        T:assert(not input_buffer.is_pressed(ctx.main, "foo"))

        T:assert(input_buffer.peek.is_down(ctx.main, "foo"))
    end)

    T("is_pressed_multi_pop", function(T)
        world("input_pressed", "foo")
        world("input_pressed", "bar")
        world("update", input_buffer.MAX_AGE / 2)
        world("input_pressed", "foo")

        T:assert(input_buffer.is_pressed(ctx.main, {"foo", "bar"}))
        T:assert(input_buffer.is_pressed(ctx.main, {"foo", "bar"}))
        T:assert(not   input_buffer.is_pressed(ctx.main, {"foo", "bar"}))
    end)

    T("is_released_pop", function(T)
        world("input_released", "foo")
        T:assert(input_buffer.is_released(ctx.main, "foo"))
        T:assert(not input_buffer.is_released(ctx.main, "foo"))
    end)
end)
