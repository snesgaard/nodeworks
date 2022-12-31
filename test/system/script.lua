local nw = require "nodeworks"
local T = nw.third.knife.test

local function wrap_system(ctx, ecs_world)
    local obs = nw.system.script().observables(ctx)

    while ctx:is_alive() do
        nw.system.script().handle_observables(ctx, obs, ecs_world)
        ctx:yield()
    end
end

T("script", function(T)
    local ecs_world = nw.ecs.entity.create()
    local world = nw.ecs.world().create()

    world:push(wrap_system, ecs_world)

    local dst = {value = 0}

    local function ai(ctx)
        local do_it = ctx:listen("do_it"):collect()

        while ctx:is_alive() do
            for _, _ in ipairs(do_it:peek()) do
                dst.value = dst.value + 1
            end
            ctx:yield()
        end

        dst.done = true
    end

    local entity = ecs_world:entity()

    T("run_before", function(T)
        nw.system.script().set(entity, ai)
        world:emit("do_it"):spin()
        T:assert(dst.value == 1)
    end)

    T("run_after", function(T)
        world:emit("do_it")
        nw.system.script().set(entity, ai)
        world:emit("do_it")
        world:spin()
        T:assert(dst.value == 2)
    end)

    T("interrupt", function(T)
        nw.system.script().set(entity, ai)
        world:emit("do_it"):spin()
        nw.system.script().stop(entity)
        world:emit("do_it"):spin()
        T:assert(dst.value == 1)
        T:assert(dst.done)
    end)

    local action_complete_token = "we did it"

    local function action(ctx, entity)
        ctx:emit(action_complete_token, true)
    end

    local function ai_with_action(ctx, entity)
        local obs = ctx:listen(action_complete_token):latest()
        nw.system.script().action.set(entity, action)
        while not obs:peek() do
            coroutine.yield()
        end
        entity.we_did_it = true
    end

    T("action", function(T)
        T:assert(not entity.we_did_it)
        nw.system.script().set(entity, ai_with_action)
        world:emit("update"):spin()
        T:assert(entity.we_did_it)
    end)


    T("bug:clear", function(T)
        -- This basically detects a bug in the scripting system where
        -- observables wouldn't be properly cleared on script yield
        --
        -- Thus this checks whehter the max size of update is only one
        local function updates(ctx, entity)
            local u = ctx:listen("update"):collect()
            while ctx:is_alive() do
                entity.updates = u:peek():size()
                ctx:yield()
            end
        end

        nw.system.script().set(entity, updates)
        world:emit("update"):spin()
        world:emit("update"):spin()
        T:assert(entity.updates == 1)
    end)
end)
