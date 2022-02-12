local nw = require "nodeworks"

local function call_if_exists(f, ...) if f then return f(...) end end

local function ai_queue() return event_queue() end

local ai = nw.ecs.system(nw.component.pushdown_automata)

function ai.on_pushed(world)
    world:singleton():ensure(ai_queue)
end

function ai.on_poped(wolrd)
    world:singleton():remove(ai_queue)
end

local implementation = {}

function implementation.push(entity, state, ...)
    local automata = entity:ensure(nw.component.pushdown_automata)

    local prev_state = automata:peek()
    if prev_state then call_if_exists(prev_state.on_obscure, entity, ...) end

    automata:push(state)

    call_if_exists(state.on_push, entity, ...)
end

function implementation.pop(entity)
    local automata = entity:ensure(nw.component.pushdown_automata)
    local prev_state = automata:pop()

    if prev_state then call_if_exists(prev_state.on_pop, entity) end

    local next_state = automata:peek()

    if next_state then call_if_exists(next_state.on_reveal, entity) end
end

function implementation.move(entity, ...)
    implementation.pop(entity)
    implementation.push(entity, ...)
end

function implementation.clear(entity)
    local automata = entity:ensure(nw.component.pushdown_automata)
    while automata:size() > 0 do implementation.pop(entity) end
end

function implementation.event(pool, event, ...)
    for _, entity in ipairs(pool) do
        local automata = entity:ensure(nw.component.pushdown_automata)
        for i = automata:size(), 1, -1 do
            local state = automata[i]
            local call = call_if_exists(state[event], entity, ...)
            local block = call_if_exists(state.block_event, entity, event, ...)
            if call or block then break end
        end
    end
end

for _, name in ipairs{"push", "pop", "clear", "move"} do
    local func = implementation[name]
    if not func then errorf("Could not find %s", name) end
    ai[name] = function(entity, ...)
        if not entity.world then return end
        local queue = entity.world:singleton():ensure(ai_queue)
        queue(func, entity, ...)
    end
end

function ai.all_event(world, pool, event, ...)
    local queue = world:singleton():ensure(ai_queue)
    queue(implementation.event, pool, event, ...)
end

return ai
