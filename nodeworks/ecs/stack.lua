local nw = require "nodeworks"

local stack = {stack = list(nw.ecs.world())}
stack.__index = stack

function stack.current() return stack.stack:tail() end

function stack.size() return stack.stack:size() end

function stack.pop()
    if 1 < stack.stack:size() then stack.stack[#stack.stack] = nil end
    return stack
end

function stack.push()
    table.insert(stack.stack, stack.current():copy())
    return stack
end

function stack.clear()
    stack.stack = list(stack.current())
    return stack
end

function stack:__call() return stack:current() end

function stack.reset()
    stack.stack = list(nw.ecs.world())
    return stack
end

local function declare_method(key, return_refence_to_stack)
    stack[key] = function(...)
        local world = stack.current()
        local f = world[key]
        if not f then return stack end

        if return_refence_to_stack then
            f(world, ...)
            return stack
        else
            return f(world, ...)
        end
    end
end

local methods = {
    {"set", true},
    {"init", true},
    {"assemble", true},
    {"visit", true},
    {"remove", true},
    {"destroy", true},
    {"get", false},
    {"ensure", false},
    {"get_table", false},
    {"has", false},
    {"view_table", false},
}

for _, m in ipairs(methods) do declare_method(unpack(m)) end
    
return setmetatable({}, stack)