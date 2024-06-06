local ecs_id = require "nodeworks.ecs.id"
local stack = require "nodeworks.ecs.stack"
local component = require "nodeworks.component"
local list = require "nodeworks.core.list"
local time = require "nodeworks.system.time"

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
        if node_status[index] ~= "success" then return node_status[index] end
    end

    return "success"
end

function assembly.sequence(root, ...)
    local status = run_sequence(
        root.nodes,
        stack.ensure(component.node_status, root),
        ...
    )

    if status ~= "pending" then stack.remove(component.node_status, root) end

    return status
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

function assembly.wait(node)
    local t = stack.ensure(component.time, node, time.clock())
    if time.clock() - t < node.duration then return "pending" end
    stack.remove(component.time, node)
    return "success"
end

function assembly.wait_until(node)
    local status = run_node(node.child)
    return status == "success" and "success" or "pending"
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

    if node.success_required <= success_count then return "success" end
    if node.success_required <= success_count + pending_count then return "pending" end

    return "failure"
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

ai.run = run_node
ai.assembly = assembly

return ai