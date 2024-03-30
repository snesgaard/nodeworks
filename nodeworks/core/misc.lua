local misc = {}

function misc.errorf(...) return error(string.format(...)) end

function misc.printf(...) return print(string.format(...)) end

function misc.class()
    local c = {}
    c.__index = c

    function c:class() return c end

    function c.constructor() return {} end

    function c.create(...)
        return setmetatable(c.constructor(...), c)
    end

    return c
end

---@param dst table
---@param src table
---@param overwrite boolean
function misc.decorate(dst, src, overwrite)
    for key, value in pairs(src) do
        local is_function = type(value) == "function"
        local is_callable = type(value) == "table" and value.__call
        if is_function or is_callable then
            if not dst[key] or overwrite then
                dst[key] = value
            else
                misc.errorf("Tried to decorate key %s to table, but was already set", key)
            end
        end
    end
end

---@param c table
---@param this table
function misc.inherit(c, this)
    local i = setmetatable(this or {}, c)
    i.__index = i

    function i:class() return i end
    function i:superclass() return c end

    return i
end

return misc