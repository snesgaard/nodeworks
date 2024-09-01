---@module "list"
local list = require "nodeworks.core.list"
---@module "misc"
local misc = require "nodeworks.core.misc"
---@module "world"
local world = require "nodeworks.ecs.world"

---@alias Id string|integer|table

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
---@param id Id
---@return R|nil
function stack.get(component, id)
    return state.world:get(component, id)
end

---@generic R
---@param component fun(...): R
---@param id Id
---@param ... any
---@return R
function stack.get_or_default(component, id, ...)
    local v = stack.get(component, id)
    return v ~= nil and v or component(...)
end

---@generic R
---@param component fun(...): R
---@param id Id
---@param ... any
function stack.set(component, id, ...)
    state.world:set(component, id, ...)
    return stack
end

---@generic R
---@param component fun(...): R
---@param id Id
---@return boolean
function stack.has(component, id)
    return state.world:has(component, id)
end

---@generic R
---@param component fun(...): R
---@param id Id
---@param ... any
---@return R
function stack.ensure(component, id, ...)
    return state.world:ensure(component, id, ...)
end

---@generic R
---@param component fun(...): R
---@param id Id
function stack.remove(component, id)
    state.world:remove(component, id)
    return stack
end

---@generic R
---@param id Id
function stack.destroy(id)
    state.world:destroy(id)
    return stack
end

---@param values table
---@param id Id
function stack.assemble(values, id)
    state.world:assemble(values, id)
    return stack
end

---@generic R
---@param component fun(...): R
---@return fun(table: table<Id, R>, key: any): Id, R
---@return table<Id, R>
function stack.view_table(component)
    return state.world:view_table(component)
end

---@generic R
---@param component fun(...): R
function stack.destroy_table(component)
    state.world:destroy_table(component)
    return stack
end

---@generic R1, R2, R3, R4, R5, R6
---@param c1 fun(...): R1
---@param c2? fun(...): R2
---@param c3? fun(...): R3
---@param c4? fun(...): R4
---@param c5? fun(...): R5
---@param c6? fun(...): R6
---@return fun(t: table, id: Id): Id, R1, R2, R3, R4, R5, R6
---@return table
function stack.view_union(c1, c2, c3, c4, c5, c6)
    return state.world:view_union(c1, c2, c3, c4, c5, c6)
end

return stack