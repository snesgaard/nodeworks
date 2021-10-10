local event_listener = {}
event_listener.__index = event_listener

function event_listener:__call(...)
    table.insert(self, {...})
end

function event_listener:has(key)
    for _, event in ipairs(self) do
        if event[1] == key then return true end
    end

    return false
end

function event_listener:get(key)
    for _, event in ipairs(self) do
        if event[1] == key then return unpack(event) end
    end
end

function event_listener:__tostring()
    return tostring(List.map(self, function(e) return e[1] end))
end

return function()
    return setmetatable({}, event_listener)
end
