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
    return node and nw.just(node) or nw.empty()
end

function Record:get_info(node)
    local info = self.info[node]
    return info and nw.just(info) or nw.empty()
end

function Record:info_from_alias(alias)
    return self
        :find(alias)
        :and_then(function(node) return self:get_info(node) end)
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

function Reducer:_invoke(state, record, f, ...)
    local state, info, next_actions = f(
        state:copy(), format_args(record, ...)
    )

    record.info[action] = info
    if action.alias then record.alias[action.alias] = action end

    for _, a in ipairs(next_actions or list()) do
        record.tree:link(action, a)
        state = self:_invoke(state, record, unpack(a))
    end

    return state
end

function Reducer:__call(state, action)
    local record = Record.create()

    local final_state = self:_invoke(state, record, unpack(action))

    if self._on_action() then
        self._on_action(action, final_state, record)
    end

    return final_state, record
end

return Reducer
