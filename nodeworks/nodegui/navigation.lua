local function is_outside_bound(min, max, lower, upper)
    return max < lower or upper < min
end

local function is_in_bound_x(min, max, shape)
    return not is_outside_bound(min, max, shape.x, shape.x + shape.w)
end

local function is_in_bound_y(min, max, shape)
    return not is_outside_bound(min, max, shape.y, shape.y + shape.h)
end

local function is_in_bound(min_x, max_x, min_y, max_y, shape)
    return is_in_bound_x(min_x, max_x, shape) and is_in_bound_y(min_y, max_y, shape)
end

local function autoconnect_right(id, shapes)
    local shape = shapes[id]


end


local navigation = {}
navigation.__index = navigation

function navigation:autoconnect(id, shapes)

end

return function()
    return setmetatable(
        {
            up = {},
            down = {},
            left = {},
            right = {},
        },
        navigation
    )
end
