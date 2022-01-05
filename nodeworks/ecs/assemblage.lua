local nw = require "nodeworks"

return function(...)
    local components = {...}
    return function(args, world)
        local entity = nw.ecs.entity(world)

        args = args or {}

        for _, c in ipairs(components) do entity:set(c, unpack(args[c] or {})) end

        return entity
    end
end
