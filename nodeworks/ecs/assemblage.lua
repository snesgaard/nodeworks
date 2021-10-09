return function(...)
    local components = {...}
    return function(args, world)
        local entity = ecs.entity(world)

        args = args or {}

        for _, c in ipairs(components) do entity:add(c, unpack(args[c] or {})) end

        return entity
    end
end
