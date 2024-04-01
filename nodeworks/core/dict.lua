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

return dict