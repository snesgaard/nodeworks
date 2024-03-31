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

---@param w integer
---@param h integer
---@param f fun(w, h, ...): nil
---@param ... any
---@return love.Canvas
function misc.prerender(w, h, f, ...)
    local args = {...}
    local prev_c = love.graphics.getCanvas()
    local c = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas({c, stencil=true})
    love.graphics.push()
    love.graphics.origin()
    f(w, h, unpack(args))
    love.graphics.pop()
    love.graphics.setCanvas(prev_c)
    return c
end

function misc.dict_to_string(d)
    local l = {}
    for key, val in pairs(d) do
      l[#l + 1] = tostring(key) .. ": " .. tostring(val)
    end
    if #l == 0 then return "{}" end
    local s = "{"
    for i = 1, #l - 1 do
      s = s .. tostring(l[i]) .. ", "
    end
    s = s .. tostring(l[#l]) .. "}"
    return s
  end

return misc