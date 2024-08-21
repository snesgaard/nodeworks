local ecs_id = require "nodeworks.ecs.id"
local stack = require "nodeworks.ecs.stack"
local component = require "nodeworks.component"
local list = require "nodeworks.core.list"
local time = require "nodeworks.system.time"

--- How to reset nodes
local reset = {}

local function reset_node(node, ...)
    local type = node.type or "unknown"
    local r = reset[type]
    if r then r(node, ...) end
end

-- How to execute nodes
local assembly = {}

local function run_node(node, ...)
    local type = node.type or "unknown"
    local ass = assembly[type]
    if not ass then return "failure" end
    return ass(node, ...)
end

local function run_sequence(nodes, node_status, ...)
    for index, node in ipairs(nodes) do
        local status = node_status[index] or "pending"
        if status == "pending" then node_status[index] = run_node(node, ...) end
        if node_status[index] ~= "success" then return node_status[index], index end
    end

    return "success", #nodes
end

local function run_sequence_defer_from(nodes, index)
    for i = index, 1, -1 do
        local n = nodes[i]
        if n.type == "defer" then n.func(unpack(n.args)) end
    end
end

function assembly.sequence(root, ...)
    local status, index = run_sequence(
        root.nodes,
        stack.ensure(component.node_status, root),
        ...
    )

    if status ~= "pending" then
        run_sequence_defer_from(root.nodes, index)
        stack.remove(component.node_status, root)
    end

    return status
end

function reset.sequence(node)
    stack.remove(component.node_status, node)

    for _, child in ipairs(node.nodes) do
        reset_node(child)
    end
end

local function run_select(nodes, node_status, ...)
    for index, node in ipairs(nodes) do
        local status = node_status[index] or "pending"
        if status == "pending" then node_status[index] = run_node(node, ...) end
        if node_status[index] ~= "failure" then return node_status[index] end
    end

    return "failure"
end

function assembly.select(root, ...)
    local status = run_select(
        root.nodes,
        stack.ensure(component.node_status, root),
        ...
    )

    if status ~= "pending" then stack.remove(component.node_status, root) end

    return status
end

function reset.select(node)
    stack.remove(component.node_status, node)

    for _, child in ipairs(node.nodes) do
        reset_node(child)
    end
end

function assembly.condition(node, ...)
    if not node.condition then return "failure" end
    return node.condition(unpack(node.args)) and "success" or "failure"
end

function assembly.action(node, ...)
    if node.action then node.action(unpack(node.args)) end
    return "success"
end

function assembly.invert(node, ...)
    local status = run_node(node.child, ...)
    if status == "pending" then
        return "pending"
    elseif status == "failure" then
        return "success"
    else
        return "failure"
    end
end

function reset.invert(node)
    return reset_node(node.child)
end

function assembly.wait(node)
    local t = stack.ensure(component.time, node, time.clock())
    if time.clock() - t < node.duration then return "pending" end
    stack.remove(component.time, node)
    return "success"
end

function reset.wait(node)
    stack.remove(component.time, node)
end

function assembly.wait_until(node)
    local status = run_node(node.child)
    return status == "success" and "success" or "pending"
end

function reset.wait_until(node)
    return reset_node(node.child)
end

function assembly.parallel(node)
    local node_status = stack.ensure(component.node_status, node)

    for index, child in ipairs(node.children) do
        node_status[index] = node_status[index] or "pending"
        if node_status[index] == "pending" then
            node_status[index] = run_node(child)
        end
    end

    local success_count = 0
    local pending_count = 0
    local failure_count = 0
    local node_count = #node.children
    
    for _, status in pairs(node_status) do
        if status == "success" then
            success_count = success_count + 1
        elseif status == "failure" then
            failure_count = failure_count + 1
        elseif status == "pending" then
            pending_count = pending_count + 1
        end
    end

    if node.success_required <= success_count then
        reset_node(node)
        return "success"
    end
    if node.success_required <= success_count + pending_count then return "pending" end

    reset_node(node)
    return "failure"
end

function reset.parallel(node)
    stack.remove(component.node_status, node)

    for _, child in ipairs(node.children) do reset_node(child) end
end

local ai = {}

function ai.sequence(args)
    return {
        type = "sequence",
        nodes = args
    }
end

function ai.select(args)
    return {
        type = "select",
        nodes = args
    }
end

function ai.condition(condition, ...)
    return {
        type = "condition",
        condition = condition,
        args = {...}
    }
end

function ai.action(action, ...)
    return {
        type = "action",
        action = action,
        args = {...}
    }
end

function ai.invert(child)
    return {
        type = "invert",
        child = child
    }
end

function ai.wait(duration)
    return {
        type = "wait",
        duration = duration
    }
end

function ai.wait_until(child)
    return {
        type = "wait_until",
        child = child
    }
end

function ai.set(...)
    return ai.action(stack.set, ...)
end

function ai.remove(...)
    return ai.action(stack.remove, ...)
end

local function cooldown_condition(token, duration)
    local t = stack.get(component.time, token)
    local c = time.clock()
    if not t or duration <= c - t then
        stack.set(component.time, token, c)
        return true
    else
        return false
    end
end

function ai.cooldown(duration)
    return ai.condition(cooldown_condition, ecs_id.weak("cooldown"), duration)
end

---@param func fun(...)
---@param ... any
function ai.node(func, ...)
    return {
        type = "generic_node",
        func = func,
        args = {...}
    }
end

function ai.parallel(children, success_count)
    return {
        type = "parallel",
        children = children,
        success_required = success_count or #children
    }
end

function ai.parallel_any(children)
    return ai.parallel(children, 1)
end

function ai.parallel_all(children)
    return ai.parallel(children, #children)
end

function ai.ignore_failure(child)
    return {
        type = "ignore_failure",
        child = child
    }
end

function assembly.ignore_failure(node)
    local status = run_node(node.child)
    if status == "failure" then return "success" end
    return status
end

function reset.ignore_failure(node)
    return reset_node(node.child)
end

function ai.bind_head(func, ...)
    return {
        type = "bind_head",
        func = func,
        channels = {...}
    }
end

function assembly.bind_head(node)
    local bl = stack.ensure(component.black_board, node)

    if not bl.child then
        local args = {}
        for index, channel in ipairs(node.channels) do
            local item = list.head(channel)
            if item == nil then return "failure" end
            args[index] = item
        end
        bl.child = node.func(unpack(args))
    end

    local status = run_node(bl.child)

    if status ~= "pending" then
        stack.remove(component.black_board, node)
    end

    return status
end

function ai.declare(name, constructor, executor, resetter)
    local prev_constructor = ai[name]
    local prev_executor = assembly[name]
    local prev_reset = reset[name]

    if prev_constructor or prev_executor or prev_reset then
        local msg = string.format(
            "Constructor (%i) or executor (%i) or reset (5i) already exists for %s",
            prev_constructor ~= nil, prev_executor~= nil, prev_reset ~= nil, name
        )
        error(msg)
    end

    ai[name] = function(...)
        local node = constructor(...)
        node.type = name
        return node
    end

    assembly[name] = executor
    reset[name] = resetter
end

---@param func fun(...)
---@param ... any
function ai.defer(func, ...)
    return {
        type = "defer",
        func = func,
        args = {...}
    }
end

function assembly.defer() return "success" end

ai.run = run_node
ai.assembly = assembly

return ai