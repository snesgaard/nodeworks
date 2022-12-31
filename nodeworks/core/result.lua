local Result = class()

function Result.create(values, msg)
    return setmetatable({_values=values, _msg=msg}, Result)
end

function Result:__tostring()
    if self:has_value() then
        return "Just: " .. tostring(self._values)
    else
        return "Error: " .. tostring(self._msg)
    end
end

function Result.just(...) return Result.create(list(...)) end

function Result.error(msg) return Result.create(nil, msg) end

Result.empty = Result.error

function Result:has_value() return self._values ~= nil end

function Result:has_error() return not self:has_value() end

function Result:value()
    self:throw()
    return self._values:unpack()
end

function Result:value_or_default(default)
    if self:has_value() then
        return self._values:unpack()
    else
        return default
    end
end

function Result:message() return self._msg or "no message" end

function Result:map(f)
    if self:has_error() then return self end
    return Result.just(f(self:value()))
end

function Result:otherwise(...)
    if self:has_value() then return self end
    return Result.just(...)
end

function Result:zip(other, ...)
    if not other then return self end
    if not other:has_value() then return other end
    if not self:has_value() then return self end
    return Result.create(self._values + other._values):zip(...)
end

local function throw_if_not_result(maybe_result)
    if type(maybe_result) ~= "table" then
        errorf("Result of and_then must be table, was %s", type(maybe_result))
    end
    if getmetatable(maybe_result) ~= Result then
        errorf("Result of and_then must be an instance of result")
    end
    return maybe_result
end

function Result:and_then(f)
    if self:has_error() then return self end
    local maybe_result = f(self:value())
    return throw_if_not_result(maybe_result)
end

function Result:or_else(f)
    if self:has_value() then return self end
    local maybe_result = f(self._error)
    return throw_if_not_result(maybe_result)
end

function Result:throw()
    if self:has_error() then errorf(self:message()) end

    return self
end

function Result:visit(f)
    if self:has_value() then f(self:value()) end
    return self
end

function Result:visit_error(f)
    if self:has_error() then f(self:message()) end
end

function Result:__add(...) return self:zip(...) end

return Result
