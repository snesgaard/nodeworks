local nw = require "nodeworks"
local Base = nw.system.base

local Decision = Base()

local function sort_by_score(task1, task2)
    return task1.score < task2.score
end

local function pick_best_task(tasks_and_scores)
    table.sort(tasks_and_scores, sort_by_score)
    local best_task = tasks_and_scores:tail()
    if not best_task then return end
    return best_task
end

local function reduce_score(sum, task)
    return sum + task.score
end

local function pick_weighted_random_rask(tasks_and_scores)
    table.sort(tasks_and_scores, sort_by_score)
    local best_task = tasks_and_scores:tail()
    if not best_task then return end
    if best_task.score == math.huge then return best_task end

    local sum_of_scores = List.reduce(tasks_and_scores, reduce_score, 0)
    local r = love.math.random()

    for _, task in ipairs(tasks_and_scores) do
        r = r - task.score
        if r <= 0 then return task end
    end

    return best_task
end

local function evaluate_decision(ctx, entity, decision)
    local tasks_and_scores = list()

    for id, func in pairs(decision) do
        local action_score = func(entity)
        if action_score and action_score.score > 0 then
            action_score.id = id
            table.insert(tasks_and_scores, action_score)
        end
    end

    local next_task = pick_weighted_random_rask(tasks_and_scores)

    if not next_task then return end

    print("next task", next_task.id)

    entity:map(nw.component.task, function(current_task)
        return current_task:set(next_task.func, ctx, unpack(next_task.args or {}))
    end)
end

local function should_evaluate_decision(entity)
    local should_decide = entity:get(nw.component.should_decide)
    if not should_decide then return true end
    return should_decide(entity)
end

function Decision.is_busy(entity)
    local task = entity:get(nw.component.task)
    return task and task:is_alive()
end

function Decision.run_decisions(ctx, ecs_world)
    local decision_table = ecs_world:get_component_table(nw.component.decision)
    for id, decision in pairs(decision_table) do
        local entity = ecs_world:entity(id)
        if should_evaluate_decision(entity, decision) then
            evaluate_decision(ctx, entity, decision)
        end
    end
end

function Decision.run_tasks(ctx, ecs_world)
    local task_table = ecs_world:get_component_table(nw.component.task)
    for id, task in pairs(task_table) do
        local res = task:resume()
        if res:has_error() then
            print("Task failed => ", res:message())
        end
    end
end

function Decision.run_decision_and_task(ctx, obs, ecs_world)
    Decision.run_decisions(ctx, ecs_world)
    Decision.run_tasks(ctx, ecs_world)
end

function Decision.observables(ctx)
    return {
        update = ctx:listen("update"):collect()
    }
end

function Decision.handle_observables(ctx, obs, ...)
    for _, dt in ipairs(obs.update:pop()) do
        for _, ecs_world in ipairs({...}) do
            Decision.run_decision_and_task(ctx, obs, ecs_world)
        end
    end
end

return Decision.from_ctx
