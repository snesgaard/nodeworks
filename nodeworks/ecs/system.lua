local system = {}
system.__index = system

function system.from_components(...)
    local components = {...}
    local function f(entity)
        for _, c in ipairs(components) do
            if not entity:has(c) then return false end
        end

        return true
    end

    return system.from_function(f)
end

function system.from_function(func)
    return {entity_filter=func}
end

function system:__call(...)
    return system.from_components(...)
end

return setmetatable(system, system)
