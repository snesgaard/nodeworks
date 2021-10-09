local maybe = {}
maybe.__index = maybe

function maybe.create(data, is_error)
    return setmetatable({__data=data, __is_error=is_error}, maybe)
end

function maybe.from_error(error) return maybe.create(error, true) end

function maybe.from_value(value) return maybe.create(value) end

function maybe:has_value()
    return not self.__is_error
end

function maybe:has_error()
    return self.__is_error
end

function maybe:value(default_value)
    if not self:has_value() and default_value == nil then
        error("Tried to extract value from an error")
    end

    return self.__data or default_value
end

function maybe:error()
    if self:has_value() then
        error("Tried to extract error from a value")
    end

    return self.__data
end

function maybe:map(f, ...)
    if not self:has_value() return self end

    local v = self:value()
    return maybe.from_value(f(v, ...))
end

function maybe:flatmap(f, ...)
    if not self:has_value() return self end

    local v = self:value()
    return f(v, ...)
end

function maybe:on_error(f, ...)
    if self:has_value() then return self end

    f(self:error(), ...)

    return self
end

return maybe
