local Record = class()

function Record.create(init_state)
    return setmetatable(
        {
            _init_state = init_state,
            _epochs = list(),
            _infos = dict(),
            _states = dict(),
            _parent = dict(),
        },
        Record
    )
end

function Record:register_epoch(action, state, info)
    if not state then
        errorf("State must be defined")
    end

    table.insert(self._epochs, {action = action, state = state, info = info})
    self._infos[action] = info
    self._states[action] = state
end

function Record:register_parent(child, parent)
    self._parent[child] = parent
end

function Record:root() return self:children(self):head() end

function Record:children(epoch)
    return self._epochs
        :filter(function(e) return self._parent[e] == epoch end)
end

function Record:epochs() return self._epochs end

function Record:state(action)
    if not action then
        local epoch = self._epochs:tail()

        return epoch and epoch.state or self._init_state
    end

    local state = self._state[action]

    if not state then
        errorf("Request for state of action %s was undefined", action.key)
    end

    return state
end

function Record:info(action)
    local info = self._infos[action]

    if not info then
        errorf("Request for info of action %s was undefined", action.key)
    end

    return info
end

local Reducer = class()

function Reducer.create(init_state, map)
    return setmetatable({state=init_state, map=map}, Reducer)
end

local function format_args(arg, record)
    if type(arg) ~= "function" then return arg end

    return arg(record)
end

local function execute_action(record, map, action, on_action, on_state, parent)
    local key = action[1]
    local m = map[key]
    if not m then errorf("Unknown action %s", key) end

    local epoch, derived_actions = m(
        record:state(), List.body(action):map(format_args, record):unpack()
    )

    if not epoch then errorf("An epoch must be returned: %s", key) end

    record:register_epoch(action, epoch.state, epoch.info)
    record:register_parent(action, parent)

    on_action(record, action)
    on_state(epoch.state)

    if not derived_actions then return end

    for _, a in ipairs(derived_actions) do
        execute_action(record, map, a, on_action, on_state, action)
    end
end

function Reducer:run(action)
    local record = Record.create(self.state)

    execute_action(record, self.map, action, self.on_action, self.on_state, record)

    self.state = record:state()
    return record
end

function Reducer.on_action(record, action)

end

function Reducer.on_state(state)

end

function Reducer.epoch(state, info) return {state=state, info=info or {}} end

return Reducer
