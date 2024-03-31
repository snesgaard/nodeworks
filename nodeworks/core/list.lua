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

---@generic T
---@param l T[]
---@return integer
function list.size(l) return #l end

---@generic T
---@generic R
---@param l T[]
---@param f fun(R, T, ...): R
---@param init R
---@param ... any
---@return R
function list.reduce(l, f, init, ...)
    local r = init
    for _, v in ipairs(l) do
        r = f(r, v, ...)
    end

    return r
end

---@generic T
---@param l T[]
---@return T|nil
function list.head(l) return l[1] end

---@generic T
---@param l T[]
---@return T|nil
function list.tail(l) return l[#l] end

---@generic T
---@param l T[]
---@return T[]
function list.body(l)
    local r = {}
    for i = 2, #l do table.insert(r, l[i]) end
    return r
end

return list