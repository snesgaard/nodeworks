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

function state:__tostring()
    return tostring(self.root)
end

function state.create(root)
    local this = {}

    if not root then
        local init = state._init or function() return {} end
        root = dict(init())
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

function state:transform(...)
    local function get_opts(tag, f, args, ...)
        if type(tag) == "function" then
            return nil, tag, f
        else
            return tag, f, args
        end
    end

    local function get_recur(tag, f, args, ...)
        if type(tag) == "function" then
            return args, ...
        else
            return ...
        end
    end

    local function inner_action(epic, state, ...)
        local tag, f, args = get_opts(...)

        if not f then
            return epic
        end

        local history = {}
        local next_history = f(state, args, history)
        epic[#epic + 1] = next_history or history

        if tag and type(tag) ~= "number" then
            if not epic[tag] then
                epic[tag] = history
            else
                log.warn("Tag <%s> was already taken", tostring(tag))
            end
        end

        return inner_action(
            epic, history:tail().state, get_recur(...)
        )
    end

    local epic = inner_action(dict(), state, ...)
    local history = epic[#epic]

    return history:tail().state, epic

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
        value = d:set(p, value)
    end

    return state.create(value)
end

function state:print()
    print(self)
    return self
end

local function valid_echo(d)
    return d.order and d.func
end

function state:set_echo(path, f)
    local parts = string.split(path, '/')
    local dirs = traverse(self.root, parts:erase())

    if not dirs or not valid_echo(dirs:tail()) then
        log.warn("Echo path <%s> not valid", path)
        return
    end

    local echo = dirs:tail()
    local func = echo.func
    local order = echo.order
    local id = parts:tail()

    func = func:set(id, f)

    local index = order:argfind(id)

    if not f then
        order = order:erase(index)
    elseif not index then
        order = order:insert(id)
    end

    echo = echo
        :set("func", func)
        :set("order", order)

    for i = #parts - 1, 1, -1 do
        echo = dirs[i]:set(parts[i], echo)
    end

    return state.create(echo)
end

-- Should remove echoes and such

function state:__call(...)
    return self:read(...)
end

return state
