local nw = require "nodeworks"

local function invoke(f, ...) return f(...) end

local execution_style = {}

function execution_style.front_to_back(queue)
    local size = #queue
    for i = 1, #queue do
        if invoke(unpack(queue[i])) then return end
    end
end

function execution_style.back_to_front(queue)
    local size = #queue
    for i = size, 1, -1 do
        if invoke(unpack(queue[i])) then return end
    end
end

local delegate_system = nw.ecs.system(nw.component.delegate_queue)

function delegate_system.run(entity)
    local queue = entity % nw.component.delegate_queue
    local execution_order = entity % nw.component.delegate_order or "back_to_front"
    local es = execution_style[execution_order]
    if es then es(queue) end
    entity:set(nw.component.delegate_queue)
end

function delegate_system.update(world, pool)
    for _, entity in ipairs(pool) do
        delegate_system.run(entity)
    end
end

return delegate_system
