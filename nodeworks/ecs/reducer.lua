local Epoch = class()

function Epoch.create(state, info, actions)
    return setmetatable(
        {_state=state, _info=info or {}, _actions=actions or list()}, Epoch
    )
end

function Epoch:state() return self._state end

function Epoch:info() return self._info end

function Epoch:actions() return self._actions end

local Record = class()

function Record.create(initial_state)
    return setmetatable(
        {epochs=list(Epoch.create(initial_state)), tags=dict(), children=dict()},
        Record
    )
end

function Record:register(epoch)
    table.insert(self.epochs, epoch)
    return self
end

function Record:state() return self.epochs:tail():state() end

function Record:tag(tag, epoch)
    if tag then self.tags[tag] = epoch end
    return self
end

function Record:link(parent, child)
    self.children[parent] = self.children[parent] or {}
    table.insert(self.children[parent], child)
    return self
end

function Record:get_children(epoch)
    return self.children[epoch] or list()
end

local function recursive_child(record, all_children, epoch)
    for _, child in ipairs(record:get_children(epoch)) do
        table.insert(all_children, child)
        recursive_child(record, all_children, child)
    end

    return all_children
end

function Record:get_all_children(epoch)
    return recursive_child(self, list(epoch), epoch)
end

function Record:find(tag) return self.tags[tag] end

local Reducer = class()

function Reducer.create(state, functor)
    return setmetatable(
        {
            _state = state,
            _functor = functor or {}
        },
        Reducer
    )
end

local function noop(state) return Epoch.create(state) end

local function format_args(record, arg, ...)
    if arg == nil then return end

    if type(arg) == "function" then
        return arg(record), format_args(record, ...)
    else
        return arg, format_args(record, ...)
    end
end

function Reducer:call_action(record, key, ...)
    local f = noop
    if key then f = self._functor[key] or noop end
    return f(record:state():copy(), format_args(record, ...))
end

local function recurse_action(reducer, record, action)
    local epoch = reducer:call_action(record, unpack(action))

    if not epoch then return epoch end

    epoch.type = action[1]

    record
        :register(epoch)
        :tag(action.tag, epoch)

    for _, sub_action in ipairs(epoch:actions()) do
        local sub_epoch = recurse_action(reducer, record, sub_action)
        record:link(epoch, sub_epoch)
    end

    return epoch
end

function Reducer:speculate(...)
    local record = Record.create(self._state)

    for _, action in ipairs{...} do recurse_action(self, record, action) end

    return record
end

function Reducer.epoch(...) return Epoch.create(...) end

return Reducer
