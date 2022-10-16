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

function component.action(action, ...)
    return {action = action, args = {...}}
end

function component.action_context(...)
    return component.context(...)
end

local Script = class()

function Script.create(ctx)
    return setmetatable({}, Script)
end

function Script.observables(ctx)
    return {all_events = ctx:listen(nw.ecs.World.ALL_EVENT):collect()}
end

function Script.handle_context(obs, entity, ctx)
    local should_run = false

    for _, event in ipairs(obs.all_events:peek()) do
        local parsed = ctx:parse_single_event(event.key, event.data)
        should_run = parsed or should_run
    end

    if should_run then ctx:resume() end
end

function Script.handle_decision(ctx, obs, entity, script, args)
    local decision_ctx = entity:ensure(
        component.context, ctx.world or ctx, script, args
    )

    Script.handle_context(obs, entity, decision_ctx)
end

function Script.handle_action(ctx, obs, entity, action, args)
    local action_ctx = entity:ensure(
        component.action_context, ctx.world, action, args
    )

    Script.handle_context(obs, entity, action_ctx)
end

function Script.handle_observables(ctx, obs, ecs_world, ...)
    if not ecs_world then return end

    local script_table = ecs_world:get_component_table(component.script)
    for id, script in pairs(script_table) do
        Script.handle_decision(
            ctx, obs, ecs_world:entity(id), script.script, script.args
        )
    end

    local action_table = ecs_world:get_component_table(component.action)
    for id, action in pairs(action_table) do
        Script.handle_action(
            ctx, obs, ecs_world:entity(id), action.action, action.args
        )
    end

    return Script.handle_observables(ctx, obs, ...)
end

function Script.set(entity, script, ...)
    Script.reset(entity)
    entity:set(component.script, script, entity, ...)
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

local Action = {}

function Action.set(entity, action, ...)
    Action.stop(entity)
    entity:remove(component.action_context)
    entity:set(component.action, action, entity, ...)
end

function Action.stop(entity)
    local ctx = entity:get(component.action_context)
    if not ctx then return end
    ctx:kill()
end

Script.action = Action

local default_instance = Script.create()

return function(ctx)
    return default_instance
end
