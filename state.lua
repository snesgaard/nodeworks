local function traverse(dir, parts, combo)
    if #parts < 1 then
        return combo
    end
    if not dir then
        return
    end
    local k = parts:head()
    local v = dir[k]
    if v then
        return traverse(
            v, parts:body(), (combo or list(dir)):insert(v)
        )
    else
        return combo
    end
end

local state = {}
state.__index = state

state.setup = {}

function state:__tostring()
    return tostring(self.root)
end

function state.create(other)
    local this = {}

    local root
    if not other then
        root = dict{}
        for _, f in pairs(state.setup) do
            f(root)
        end
    else
        root = other.root
    end

    this.root = root

    return setmetatable(this, state)
end

function state:read(path)
    local parts = string.split(path, '/')
    local t = traverse(self.root, parts)
    if t and #t > #parts then return t:tail() end
end

function state:map(path, m, ...)
    local v = self:read(path)
    return self:write(path, m(v, ...))
end

function state:write(path, value)
    local parts = string.split(path, '/')
    local dirs = traverse(self.root, parts)

    if not dirs then
        log.warn("Path <%s> not valid", path)
        return self
    end

    for i = #parts, 1, -1 do
        local d = dirs[i]
        local p = parts[i]
        if not d then
            local msg = string.format("Path not found <%s>", path)
            error(msg)
        end
        value = d:set(p, value)
    end

    return state.create(value)
end

function state:print()
    print(self)
    return self
end

function state:__call(...)
    return self:read(...)
end

function state.module(api)

end

return state
