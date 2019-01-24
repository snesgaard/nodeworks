local echo = {}
echo.__index = echo

function echo:listen(f, ...)
    local args = {...}
    local n_args = #args

    local function g(v)
        args[n_args + 1] = v
        local ret = {f(unpack(args))}
        args[n_args + 1] = nil
        return unpack(ret)
    end

    self.__stack = this.__stack:insert(g)
    return g
end

function echo:partial(g, f)
    self.__sublistener[g] = f
    return self
end

function echo:remove(g)
    local i = self.__stack:argfind(function(v) return v == g end)
    if i then
        self.__stack = self.__stack:erase(i)
    end
    self.__sublistener[g] = nil
    return self
end

function echo:__call(v)
    local s = self.__stack
    for i, g in ipairs(s) do
        v = g(v) or v
        local f = self.__sublistener[g]
        if f then f(v) end
    end
    return v
end

function echo:clear()
    self.__stack = list()
    return self
end

return function()
    local this = {}
    this.__stack = list()
    this.__sublistener = dict()
    return setmetatable(this, echo)
end
