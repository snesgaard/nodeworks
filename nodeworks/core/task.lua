local Task = class()

function Task.nw()
    return require("nodeworks")
end

function Task.constructor(func, ...)
    return {_func=func, _args=list(...)}
end

function Task.compare(func1, args1, func2, args2)
    return func1 == func2 and args1 == args2
end

function Task.__eq(item, other)
    return Task.compare(item._func, item._args, other._func, other._args)
end

function Task:is_alive()
    local status = self._co and coroutine.status(self._co) or "suspended"
    return status ~= "dead"
end

local function handle_resume_return(status, msg, ...)
    return status and Task.nw().just(msg, ...) or Task.nw().empty(msg)
end

function Task:resume()
    if not self._func then return Task.nw().just() end
    self._co = self._co or coroutine.create(self._func)
    if not self:is_alive() then return Task.nw().just() end
    return handle_resume_return(coroutine.resume(self._co, unpack(self._args)))
end

function Task:set(...)
    local other = Task.create(...)
    return self == other and self or other
end

return Task
