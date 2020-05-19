local behavior = {}
behavior.__index = behavior

function behavior.create(func, ...)
    local this = {
        __children = {},
        __func = func,

    }
    local this = setmetatable(this, behavior)

    if func then
        this.__co = coroutine.create(func)
        local status, msg = coroutine.resume(this.__co, this, ...)
        if not status then errorf(msg) end
    end

    return this
end

function behavior.on_clean() end

function behavior:clean()
    self:on_clean()

    for _, child in pairs(self.__children) do
        child:destroy()
    end

    return self
end

function behavior:destroy()
    self:clean()
    if self.__co then event:clear(self.__co) end
    return self
end

function behavior:child(func, ...)
    local t = type(func)

    if t == "function" then
        self:remove(func)
        self.__children[func] = behavior.create(func, ...)
    elseif t == "table" then
        for _, f in pairs(func) do self:child(f) end
    end

    return self
end

function behavior:remove(func)
    local t = type(func)

    if t == "function" and self.__children[func] then
        self.__children[func]:destroy()
        self.__children[func] = nil
    elseif t == "table" then
        for _, f in pairs(func) do self:remove(f) end
    end

    return self
end

function behavior:__call(...) return self:child(...) end

return behavior.create
