local Node = {}
Node.__index = Node

function Node.create(f, ...)
    local this = {
        __group = {
            tween = {},
            thread = {},
            event = {},
        },
        alive = true,
        __cleaners = {},
        __children = Dictionary.create(),
        __parent = nil,
        __threads2update = {
            front = {},
            back = {}
        },
        __transform = {
            pos = vec2(0, 0),
            angle = 0,
            scale = vec2(1, 1)
        },
        on_destroyed = event()
    }
    if type(f) == "table" then
        f.create = f.create or function() end
        setmetatable(f, {__index = Node})
        f.__index = f
        this = setmetatable(this, f)
        this:set_order()
        this:__make_order()
        f.create(this, ...)
        --this.draw = f.draw
    elseif type(f) == "function" then
        this = setmetatable(this, Node)
        this:set_order()
        this:__make_order()
        f(this)
    else
        this = setmetatable(this, Node)
        this:set_order()
        this:__make_order()
    end

    return this
end

function Node:destroy()
    for co, cleanup in pairs(self.__cleaners) do
        cleanup(true)
    end
    if self.on_destroyed then self.on_destroyed(self) end
    self.alive = false
    if self.__parent then
        self.__parent.__children[self] = nil
        self.__parent:__make_order()
        self.__parent = nil
    end
end

function Node:set_order(order_func)
    local function temporal_order(a, b)
        return self.__children[a] < self.__children[b]
    end

    self.__order_func = order_func or temporal_order
end

function Node:update(dt)
    timer.update(dt, self.__group.tween)
    local f, b = self.__threads2update.front, self.__threads2update.back
    self.__threads2update.front = b
    self.__threads2update.back = f
    for co, _ in pairs(f) do
        f[co] = nil
        local status, msg = coroutine.resume(co, dt)
        if not status then
            log.error(msg)
        end
    end
    self:__update(dt)

    for _, node in ipairs(self.__node_order) do
        node:update(dt)
    end
end

function Node:draw(x, y, r, sx, sy, ...)
    local t = self.__transform
    gfx.push()
    gfx.translate((x or 0) + t.pos.x, (y or 0) + t.pos.y)
    gfx.rotate((r or 0) + t.angle)
    gfx.scale((sx or 1) * t.scale.x, (sy or 1) * t.scale.y)

    self:__draworder(0, 0, ...)

    gfx.pop()
end

function Node:__draworder(x, y, ...)
    self:__draw(0, 0, ...)
    self:__childdraw(0, 0)
end

function Node:__childdraw(...)
    for _, node in ipairs(self.__node_order) do
        node:draw(0, 0)
    end
end

function Node:adopt(child)
    local other = child.__parent
    if other then
        other.__children[child] = nil
        other:__make_order()
    end

    child.__parent = self
    self.__children[child] = love.timer.getTime()
    self:__make_order()
    return self
end

function Node:orphan(child)
    if child then
        self.__children[child] = nil
        self:__make_order()
    elseif self.__parent then
        local p = self.__parent
        p.__children[self] = nil
        p:__make_order()
        self.__parent = nil
    end
    return self
end

function Node:child(...)
    local node = Node.create(...)
    self.__children[node] = love.timer.getTime()
    node.__parent = self
    self:__make_order()
    return node
end

function Node:__make_order()
    self.__node_order = self.__children
        :keys()
        :sort(self.__order_func)
end

function Node:__update(dt) end

function Node:__draw() end

function Node:fork(f, ...)
    if not f then return end
    -- Insert a reference to self as first argument
    local co = coroutine.create(f)
    -- Maybe it is unnecessary to
    self.__group.thread[co] = true
    local status, msg = coroutine.resume(co, self, ...)
    if not status then
        log.error(msg)
    end
    return co
end

function Node:join(args)
    co = args[1]
    local kill_tweens = args.kill_tweens or true
    if not co then
        for co, cleanup in pairs(self.__cleaners) do
            cleanup(kill_tweens)
        end
        self.__group.thread = {}
        self.__cleaners = {}
    else
        self.__group.thread[co] = nil
        cleanup = self.__cleaners[co]
        if cleanup then
            cleanup(kill_tweens)
        end
    end
end

function Node:set_state(state, ...)
    if not state then return self end

    if self.__state and self.__state.exit then
        self.__state.exit(self, state)
    end

    local prev_state = self.__state
    self.__state = state
    if state.enter then
        state.enter(self, prev_state, ...)
    end

    return self
end

function Node:wait_update(...)
    local co = coroutine.running()
    self.__threads2update.front[co] = true
    return coroutine.yield(...)
end

function Node:wait(...)
    local events = {...}

    if #events == 0 then
        return
    end

    local co = coroutine.running()
    local listeners = {}

    -- Declare cleanup function, unsubs listeners and remove the cleanup
    local function cleanup(kill_tweens)
        self.__cleaners[co] = nil
        for e, l in pairs(listeners) do
            if istype(Event, e) or type(e) == "number" then
                l:remove()
            -- If it is a tween, simply remove the finish field
            else
                e.finishField = nil
                -- If this is called by threadjion, we want to stop the tween
                if kill_tweens then
                    e:remove()
                end
            end
        end
    end
    -- Cache cleanup in case we need to destory the node later
    self.__cleaners[co] = cleanup
    -- Declare continuation called
    local function continuation(e, ...)
        local args = {event = e, ...}
        cleanup()
        local status, msg
        if #events > 1 then
            status, msg = coroutine.resume(co, args)
        else
            status, msg = coroutine.resume(co, ...)
        end
        if not status then
            log.error(msg)
        end
    end

    for _, e in ipairs(events) do
        local function callback(...)
            continuation(e, ...)
        end
        -- If it is a number we assume a temporal wait in seconds
        if type(e) == "number" then
            local function timeout()
                continuation("timeout")
            end
            listeners[e] = timer.after(e, timeout)
                :remove()
                :group(self.__group.tween)
        -- Determine whether is a an event
        elseif e.listen then
            listeners[e] = e:listen(callback)
        -- or a tween
        elseif e.finish then
            e:remove():group(self.__group.tween)
            listeners[e] = e:finish(callback)
        end
    end

    return coroutine.yield()

end

return Node
