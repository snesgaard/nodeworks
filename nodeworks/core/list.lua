local list = {}

---@generic T
---@generic R
---@param l T[]
---@param f fun(T, ...): R
---@param ... any
---@return R[]
function list.map(l, f, ...)
    local r = {}

    for i, v in ipairs(l) do
        r[i] = f(v, ...)
    end

    return r
end


---@generic T
---@param l T[]
---@param f fun(T, ...): boolean
---@param ... any
---@return T[]
function list.filter(l, f, ...)
    local r = {}

    for i, v in ipairs(l) do
        if f(v, ...) then table.insert(r, v) end
    end

    return r
end

---@generic T
---@param l T[]
---@param from integer
---@param to integer
---@return T[]
function list.sublist(l, from, to)
    local r = {}

    for i = from, to do
        table.insert(r, l[i])
    end

    return r
end

return list