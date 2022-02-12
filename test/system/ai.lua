local nw = require "nodeworks"
local T = nw.third.knife.test

local scene = {}

function scene.on_push(context)
    context.main = context:entity()
end

local state = {}

function state.foo(entity, value)
    entity.a = value
end

function state.on_obscure(entity)
    entity.baz = 3
end

local state2 = {}

function state2.foo(entity, value)
    entity.a = value + 1
    entity.b = value
    return true
end

function state2.on_pop(entity)
    entity.c = 2
end

T("ai", function(T)
    local world = nw.ecs.world{nw.system.ai}
    local ctx = world:push(scene):find(scene)

    T("event", function(T)
        T:assert(#ctx:register_pool(nw.system.ai) == 0)
        nw.system.ai.push(ctx.main, state)
        world("foo", 22)
        T:assert(#ctx:register_pool(nw.system.ai) == 1)
        T:assert(ctx.main.a == 22)
        nw.system.ai.push(ctx.main, state2)
        world("foo", 22)
        T:assert(ctx.main.a == 23)
        T:assert(ctx.main.b == 22)
        T:assert(ctx.main.baz == 3)
        nw.system.ai.pop(ctx.main)
        T:assert(ctx.main.c == 2)
    end)
end)
