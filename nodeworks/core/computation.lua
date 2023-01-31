local records = setmetatable({}, {__mode = "k"})

local function peek_record(co)
    local co = co or (coroutine.running() or "__main__")
    local r = records[co]
    if not r then
        r = list()
        records[co] = r
    end
    return r
end

local function pop_record(co)
    local co = co or (coroutine.running() or "__main__")
    local r = peek_record(co)
    local co = coroutine.running() or "__main__"
    records[co] = nil
    return r
end

local function enter_computation(func, ...)
    local info = func(...)
    local record = peek_record()
    table.insert(record, dict{func=func, info=info})
    return info
end

local Status = class()

function Status.constructor(co, status, ...)
    local is_alive = coroutine.status(co) ~= "dead"
    local is_error = not status
    return {
        co = co,
        _values = list(...),
        _is_success = not is_alive and not is_error,
        _is_pending = is_alive and not is_error,
        _is_failure = is_error
    }
end

function Status:is_pending() return self._is_pending end

function Status:is_success() return self._is_success end

function Status:is_failure() return self._is_failure end

function Status:resume(...)
    if not self._conmsumed then
        self._conmsumed = true
        return Status.create(self.co, coroutine.resume(self.co, ...))
    else
        errorf("Tried to resume already consumed computation")
    end
end

function Status:values() return unpack(self._values) end

function Status:peek_record() return peek_record(self.co) end

function Status:pop_record() return pop_record(self.co) end

local function compute(func, ...)
    local co = coroutine.create(func)
    return Status.create(co, coroutine.resume(co, ...))
end

local API = class()

function API:__call(...) return compute(...) end

function API.enter(...) return enter_computation(...) end

function API.record_storage() return records end

return API.create()