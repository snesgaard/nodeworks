---@module "misc"
local misc = require "nodeworks.core.misc"

---@class WeakID
---@field tag string
local WeakID = misc.class()

---@param tag string
---@return WeakID
function WeakID.new(tag)
    return setmetatable({tag=tag or "generic"}, WeakID)
end

function WeakID:__tostring()
    return string.format("__WeakID[%s]", self.tag)
end

local StrongID = {
    counters = {}
}

function StrongID.get(tag)
    local tag = tag or "generic"
    local c = StrongID.counters[tag] or 1
    StrongID.counters[tag] = c + 1
    return c
end

local id = {}

---@param tag string
function id.strong(tag)
    local c = StrongID.get(tag)
    return string.format("%s[%i]", tostring(tag), c)
end

---@param tag string
function id.weak(tag) return WeakID.new(tag) end

return id