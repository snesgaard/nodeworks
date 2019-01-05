local id_gen = {}

local global_registry = Dictionary.create()

function id_gen.reset()
    global_registry = Dictionary.create()
end

function id_gen.register(obj)
    local name = tostring(obj)

    if not global_registry[name] then
        global_registry[name] = Dictionary.create()
    end
    local registry = global_registry[name]

    local function get_index()
        for i = 1, #registry do
            if not registry[i] then
                return i
            end
        end
        return #registry + 1
    end

    local index = get_index()
    local id = string.format("%s_%04d", name, index)
    registry[index] = id
    return id
end

function id_gen.unregister(id)
    local name, index = string.match(id, "(.+)_(%d+)")
    index = tonumber(index)

    registry = global_registry[name]
    if not registry then
        log.warn("Name %s was not found", id)
        return
    end

    registry[index] = nil
end


return id_gen
