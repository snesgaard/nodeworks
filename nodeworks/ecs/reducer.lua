local nw = require "nodeworks"

local Action = class()

function Action:func() return self[1] end

local function ignore_first(first, ...) return ... end

function Action:args() return ignore_first(unpack(self)) end

local function invoke(state, func, ...) return func(state, ...) end

function Action:__call(state) return invoke(state, unpack(self)) end

local Record = class()

function Record.create()
    return setmetatable(
        {
            tree = nw.component.tree(),
            info = dict(),
            alias = dict()
        },
        Record
    )
end

function Record:find(alias)
    return self.alias[alias]
end

function Record:maybe_find(alias)
    local node = self.alias[alias]
    return node and nw.just(node) or nw.empty()
end

function Record:maybe_info(node)
    local info = self.info[node]
    return info and nw.just(info) or nw.empty()
end

function Record:maybe_info_from_alias(alias)
    return self
        :maybe_find(alias)
        :and_then(function(node) return self:maybe_info(node) end)
end

local Reducer = class()

function Reducer.create()
    return setmetatable({}, Reducer)
end

local function invoke_action(state, record, f, ...)
    return f(state, format_args(record, ...))
end

local function create_if_func(action, record)
    if type(action) == "table" then
        return action
    elseif type(action) == "function" then
        return action(record)
    else
        errorf("Unsupported actiont type %s", action)
    end
end

function Reducer:_invoke(state, record, action)
    local action = Reducer.action(create_if_func(action, record))
    local state, info, next_actions = action(state)

    record.info[action] = info
    if action.alias then record.alias[action.alias] = action end

    for _, a in ipairs(next_actions or list()) do
        record.tree:link(action, a)
        state = self:_invoke(state, record, a)
    end

    return state
end

function Reducer:__call(state, action)
    local record = Record.create()

    local final_state = self:_invoke(state, record, action)

    self.on_action(action, final_state, record)

    return final_state, record
end

function Reducer.on_action() end

function Reducer.action(action)
    return setmetatable(action, Action)
end

return Reducer
