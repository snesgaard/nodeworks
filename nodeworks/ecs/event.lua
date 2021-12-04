local event = {}
event.__index = event

function event:key() return self.__key end

function event:args() return unpack(self.__args) end

function event:filter(f)
    self.__filter = f
    return self
end

function event:queue(world)
    return world:event_obj(self)
end

function event:invoke(world)
    return self:queue(world):spin()
end

return function(key, ...)
    local this = {
        __key = key,
        __args = {...}
    }

    return setmetatable(this, event)
end
