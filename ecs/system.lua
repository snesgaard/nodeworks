local system = {}
system.__index = system

function system.from_components(...)
    local components = {...}

    local function f(entity)
        return {pool = entity:has(unpack(components))}
    end

    return system.from_function(f)
end

function system.from_function(func)
    return {__pool_filter=func}
end

function system:__call(...)
    return system.from_components(...)
end

return setmetatable(system, system)
