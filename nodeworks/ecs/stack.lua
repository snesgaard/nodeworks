---@module "list"
local list = require "nodeworks.core.list"
---@module "misc"
local misc = require "nodeworks.core.misc"
---@module "world"
local world = require "nodeworks.ecs.world"


local state = {
    world = world()
}

local stack = {}

function stack.clear()
    state.world = world()
end

---@generic R
---@param component fun(...): R
---@return table<any, R>
function stack.get_table(component)
    return state.world:get_table(component, false)
end

---@generic R
---@param component fun(...): R
---@param id any
---@return R|nil
function stack.get(component, id)
    return state.world:get(component, id)
end

---@generic R
---@param component fun(...): R
---@param id any
---@param ... any
function stack.set(component, id, ...)
    state.world:set(component, id, ...)
    return stack
end

---@generic R
---@param component fun(...): R
---@param id any
---@return boolean
function stack.has(component, id)
    return state.world:has(component, id)
end

---@generic R
---@param component fun(...): R
---@param id any
---@param ... any
---@return R
function stack.ensure(component, id, ...)
    return state.world:ensure(component, id)
end

---@generic R
---@param component fun(...): R
---@param id any
function stack.remove(component, id)
    state.world:remove(component, id)
    return stack
end

---@generic R
---@param id any
function stack.destroy(id)
    state.world:destroy(id)
    return stack
end

---@param values table
---@param id any
function stack.assemble(values, id)
    state.world:assemble(values, id)
    return stack
end

---@generic R
---@param component fun(...): R
---@return fun(table: table<any, R>, key: any): any, R
---@return table<any, R>
function stack.view_table(component)
    return state.world:view_table(component)
end

---@generic R
---@param component fun(...): R
function stack.destroy_table(component)
    state.world:destroy_table(component)
    return stack
end

return stack