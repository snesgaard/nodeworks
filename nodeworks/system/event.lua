---@module "stack"
local stack = require "nodeworks.ecs.stack"
---@module "misc"
local misc = require "nodeworks.core.misc"
---@module "dict"
local dict = require "nodeworks.core.dict"

local function event_back() return {} end

---@param t table
local function event_front(t) return t or {} end

local system_id = "__event_system__"

local event = {}

---@generic R
---@param event_type fun(...): R
---@param ... any
function event.emit(event_type, ...)
    local e = event_type(...)
    local b = stack.ensure(event_back, system_id)
    b[event_type] = b[event_type] or {}
    table.insert(b[event_type], e)
end

---@generic R
---@param event_type fun(...): R
---@return R[]
function event.get(event_type)
    local f = stack.ensure(event_front, system_id)
    f[event_type] = f[event_type] or {}
    return f[event_type]
end


---@generic R
---@param event_type fun(...): R
---@return fun(table: R[], i?: integer): integer, R
---@return R[]
---@return integer
function event.view(event_type)
    return ipairs(event.get(event_type))
end

---@return boolean Whether there's still events to be processed
function event.swap()
    local eb = stack.ensure(event_back, system_id)
    stack.remove(event_back, system_id)
    stack.set(event_front, system_id, eb)
    -- If any messages are present, r   eturn true!
    return not dict.is_empty(eb)
end


---@param f (fun(...: any): nil)|nil
---@param ... any
function event.spin(f, ...)
    while event.swap() do
        if f then f(...) end
    end
end

return event