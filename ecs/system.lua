local system = {}

function system.create(components)
    return {__components=components}
end

return system.create
