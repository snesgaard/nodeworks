---@module "misc"
local misc = require "nodeworks.core.misc"

local WeakTable = {__mode = "k"}
WeakTable.__index = WeakTable

function WeakTable.instance()
    return setmetatable({}, WeakTable)
end

---@class World
---@field component_tables table
---@field copy_on_write table
local World = misc.class()

---@return World
function World.new(previous_components)
    local this = {
        component_tables = {},
        copy_on_write = {},
    }

    if previous_components then
        for comp, tab in pairs(previous_components) do
            this.component_tables[comp] = tab
            this.copy_on_write[comp] = true
        end
    end

    return setmetatable(this, World)
end

function World:copy() return World.new(self.component_tables) end

---@generic R
---@param component fun(...): R
---@param respect_cow boolean
---@return table<any, R>
function World:get_table(component, respect_cow)
    if type(component) ~= "function" then
        misc.errorf("Component must be a function, but was %s", type(component))
    end
 
    local c = self.component_tables[component]
    if not c then
        local c = WeakTable.instance()
        self.component_tables[component] = c
        return c
    end

    if not self.copy_on_write[component] or not respect_cow then return c end
    
    local next_c = misc.deepcopy(c)

    self.copy_on_write[component] = nil
    self.component_tables[component] = next_c
    return next_c
end

---@generic R
---@param component fun(...): R
---@param id any
---@return R|nil
function World:get(component, id)
    return self:get_table(component, false)[id]
end

---@generic R
---@param component fun(...): R
---@param id any
---@param ... any
---@return World
function World:set(component, id, ...)
    local c = self:get_table(component, true)
    local value = component(...)
    c[id] = value
    return self
end

---@generic R
---@param component fun(...): R
---@param id any
---@return boolean
function World:has(component, id)
    local v = self:get(component, id)
    return v ~= nil
end

---@generic R
---@param component fun(...): R
---@param id any
---@param ... any
---@return R
function World:ensure(component, id, ...)
    self:init(component, id, ...)
    return self:get(component, id)
end

---@generic R
---@param component fun(...): R
---@param id any
---@param ... any
---@return World
function World:init(component, id, ...)
    if not self:has(component, id) then self:set(component, id, ...) end
    return self
end

---@generic R
---@param component fun(...): R
---@param id any
function World:remove(component, id)
    local c = self:get_table(component, true)
    c[id] = nil

    return self
end

---@param id any
function World:destroy(id)
    local col = require("nodeworks.system.collision")
    col.unregister(id)
    for comp, tab in pairs(self.component_tables) do self:remove(comp, id) end
end

---@generic R
---@param component fun(...): R
---@return integer
function World:count(component)
    local t = self:get_table(component, false)
    local i = 0
    for _, _ in pairs(t) do i = i + 1 end
    return i
end

local function assemble_format(id, comp, ...)
    return comp, id, ...
end

---@param values table
---@param id any
---@return World
function World:assemble(values, id)
    for _, v in ipairs(values) do
        if type(v) ~= "table" then misc.errorf("Values must be tables") end
        local c = v[1]
        if c then self:set(assemble_format(id, unpack(v))) end
    end
    return self
end

---@generic R
---@param component fun(...): R
---@return fun(table: table<any, R>, key: any): any, R
---@return table<any, R>
function World:view_table(component)
    return next, self:get_table(component, false)
end

---@generic R
---@param component fun(...): R
---@return World
function World:destroy_table(component)
    self.component_tables[component] = nil
    return self
end

return World.new