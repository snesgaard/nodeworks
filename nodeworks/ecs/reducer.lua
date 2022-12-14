local nw = require "nodeworks"

local Info = class()

function Info.constructor()
    return {actions=list()}
end

function Info:iter()
    local function visit(info)
        coroutine.yield(info)

        for _, a in ipairs(info.actions) do visit(a()) end
    end

    return coroutine.wrap(function() visit(self) end)
end

local Action = class()

function Action.constructor(func, ...)
    return {_func=func, _args={...}}
end

function Action:evaluate(state)
    self._info = Info.create()
    self._func(self._info, state, unpack(self._args))
    return self._info
end

function Action:__call()
    if not self._info then
        error("Action has not been evaluated")
    end

    return self._info
end

local MaybeAction = class()

function MaybeAction.constructor(func, ...)
    return {_func=func, _args={...}}
end

function MaybeAction:evaluate(state)
    self._action = self._action or Action.create(self._func(unpack(self._args)))
    return self._action:evaluate(state)
end

function MaybeAction:__call()
    if not self._action() then
        error("MaybeAction has not been evaluated")
    end
    return self._action()
end

function Info:action(...)
    local action = Action.create(...)
    table.insert(self.actions, action)
    return action
end

function Info:maybe_action(...)
    local maybe_action = MaybeAction.create(...)
    table.insert(self.actions, maybe_action)
    return maybe_action
end

local Reducer = class()

function Reducer.constructor(breath_first)
    return {_depth_first=not breath_first}
end

function Reducer:__call(state, ...)
    local action = Action.create(...)
    local action_queue = list(action)
    local action_complete = list()

    while action_queue:size() > 0 do
        local next_action = action_queue:head()
        local info = next_action:evaluate(state)
        table.insert(action_complete, next_action)
        self.post(info)
        local sub_actions = info.actions

        if self._depth_first then
            action_queue = sub_actions + action_queue:body()
        else
            action_queue = action_queue:body() + sub_actions
        end
    end

    for _, action in ipairs(action_complete) do
        self.on_action(state, action)
    end

    return action()
end

function Reducer.on_action() end

function Reducer.post() end

return Reducer.create
