local system = {}

function system.create(...)
    return {__components={...}}
end

return system.create
