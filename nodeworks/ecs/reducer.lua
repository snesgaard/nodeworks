local Result = nw.Result

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
    local node = self.alias[alias]
    return node and Result.just(node) or Result.empty()
end

function Record:get_info(node)
    local info = self.info[node]
    return info and Result.just(info) or Result.empty()
end

local Reducer = class()

local function format_args(record, arg, ...)
    if arg == nil then
    elseif type(arg) == "function" then
        return arg(record), format_args(record, ...)
    else
        return arg, format_args(record, ...)
    end
end

function Reducer:_call_functor(state, action_name, ...)
    local f = self._functor[action_name]
    if not f then return end
    return f(state, ...)
end

function Reducer:_invoke(state, record, action_name, ...)
    local f = self._functor[action_name]

    if not f then return state end

    local state, info, next_actions = f(
        state, format_args(record, ...)
    )

    record.info[action] = info
    if action.alias then record.alias[action.alias] = action end

    for _, a in ipairs(next_actions) do
        record.tree:link(action, a)
        state = self:_invoke(state, record, a)
    end

    return state
end

function Reducer:__call(state, action)
    local record = {
        tree = nw.component.tree(),
        info = dict(),
        alias = {}
    }

    local final_state = self:_invoke(state, record, action)

    return state, record
end

return Reducer
