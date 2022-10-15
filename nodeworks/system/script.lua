local nw = require "nodeworks"

--[[
Requirements:

* All state must be contained in an ECS_World
* Should only be advanced upon calling the update function
* Should comply with the handle_observables API
* Shoudl comply with systems API


]]--

local component = {}

function component.script(script, ...)
    return {script = script, args = {...}}
end

function component.context(world, script, args)
    local ctx = nw.ecs.World.Context.create(world, script, unpack(args))
    ctx:resume()
    return ctx
end

local Script = class()

function Script.create(ctx)
    return setmetatable({}, Script)
end

function Script.observables(ctx)
    return {all_events = ctx:listen(nw.ecs.World.ALL_EVENT):collect()}
end

function Script.handle_entity(ctx, obs, entity, script, args)
    local ctx = entity:ensure(
        component.context, ctx.world or ctx, script, args
    )

    local should_run = false

    for _, event in ipairs(obs.all_events:peek()) do
        should_run = ctx:parse_single_event(event.key, event.data) or should_run
    end

    if should_run then ctx:resume() end
end

function Script.handle_observables(ctx, obs, ecs_world, ...)
    if not ecs_world then return end

    local script_table = ecs_world:get_component_table(component.script)

    for id, script in pairs(script_table) do
        Script.handle_entity(
            ctx, obs, ecs_world:entity(id), script.script, script.args
        )
    end

    return Script.handle_observables(ctx, obs, ...)
end

function Script.set(entity, script, ...)
    Script.reset(entity)
    entity:set(component.script, script, ...)
end

function Script.reset(entity)
    Script.stop(entity)
    entity:remove(component.context)
end

function Script.stop(entity)
    local ctx = entity:get(component.context)
    if not ctx then return end
    ctx:kill()
end

local default_instance = Script.create()

return function(ctx)
    return default_instance
end
