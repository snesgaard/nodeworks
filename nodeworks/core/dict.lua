local dict = {}

---@param d table<any, any>
---@return boolean
function dict.is_empty(d)
    for _, _ in pairs(d) do return false end
    return true
end

---@param d table<any, any>
---@return integer
function dict.size(d)
    local s = 0

    for _, _ in pairs(d) do
        s = s + 1
    end

    return s
end

---@param d table<any, any>
---@return any[]
function dict.keys(d)
    local r = {}

    for k, _ in pairs(d) do table.insert(r, k) end

    return r
end

---@param d table<any, any>
---@return any[]
function dict.values(d)
    local r = {}
    
    for _, v in pairs(d) do table.insert(r, v) end

    return r
end

local EMPTY_TABLE = {}

local function find_next_union_key(table_of_tables, init_key)
    local init_table = table_of_tables[1] or EMPTY_TABLE

    for k, _ in next, init_table, init_key do
        local good = true
        for _, other_table in next, table_of_tables, 1 do
            if other_table[k] == nil then
                good = false
                break
            end
        end
        if good then return k end
    end
end

local function read_key_value(table_of_tables, key, table_index)
    local table_index = table_index or 1
    if #table_of_tables < table_index then return end
    return table_of_tables[table_index][key], read_key_value(table_of_tables, key, table_index + 1)
end

---@generic K
---@param t table<K, any>[]
---@param key K
---@return K
---@return ...
local function view_union_iterator(t, key)
    local next_key = find_next_union_key(t, key)
    return next_key, read_key_value(t, next_key)
end


---@generic K
---@param ... table<K, any>
---@return fun(t: table, i?: K): K, ...
---@return table
function dict.view_union(...)
    local t = {...}
    return view_union_iterator, t
end

return dict