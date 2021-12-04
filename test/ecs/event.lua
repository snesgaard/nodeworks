local nw = require "nodeworks"
local T = nw.third.knife.test

local mover_system = nw.ecs.system(nw.component.position)

function mover_system:move(v)
    for _, entity in ipairs(self.pool) do
        entity[nw.component.position] = v
    end
end

local function flag_component(flag) return flag end

local function foo_filter(entity)
    return entity[flag_component] == "foo"
end

local function bar_filter(entity)
    return entity[flag_component] == "bar"
end

T("ecs.event", function(T)
    local world = nw.ecs.world{mover_system}

    local init_position = vec2(0, 0)
    local next_position = vec2(1, 1)

    local A = nw.ecs.entity(world)
        + {nw.component.position, init_position:unpack()}
        + {flag_component, "foo"}

    local B = nw.ecs.entity(world)
        + {nw.component.position, init_position:unpack()}
        + {flag_component, "bar"}

    T("move_both", function(T)
        world("move", next_position)

        T:assert(A[nw.component.position].x == next_position.x)
        T:assert(A[nw.component.position].y == next_position.y)

        T:assert(B[nw.component.position].x == next_position.x)
        T:assert(B[nw.component.position].y == next_position.y)
    end)

    T("move_both_via_event", function(T)
        nw.ecs.event("move", next_position)
            :invoke(world)

        T:assert(A[nw.component.position].x == next_position.x)
        T:assert(A[nw.component.position].y == next_position.y)

        T:assert(B[nw.component.position].x == next_position.x)
        T:assert(B[nw.component.position].y == next_position.y)
    end)

    T("move_only_A", function(T)
        world:filter_event(foo_filter, "move", next_position):spin()

        T:assert(A[nw.component.position].x == next_position.x)
        T:assert(A[nw.component.position].y == next_position.y)

        T:assert(B[nw.component.position].x == init_position.x)
        T:assert(B[nw.component.position].y == init_position.y)
    end)
end)
