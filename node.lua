local Node = {}
Node.__index = Node

Node.draw_origin = false

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
            scale = vec2(1, 1),
        }
    }
    if type(f) == "table" then
        f.create = f.create or function() end
        f.__index = f.__index or f
        if not getmetatable(f) then
            local t = {__index = Node}
            setmetatable(t, Node)
            setmetatable(f, t)
        end
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
    for co, _ in pairs(self.__group.thread) do
        event:clear(co)
    end

    if self.on_destroyed then
        self.on_destroyed(self)
    end

    event:invoke(self, "on_destroyed", self)

    self.alive = false
    if self.__parent then
        self.__parent.__children[self] = nil
        self.__parent:__make_order()
        self.__parent = nil
    end
end

function Node:invoke(key, ...)
    local f = self[key]
    if f then f(self, ...) end

    for _, node in ipairs(self.__node_order) do
        node:invoke(key, ...)
    end

    return self
end

function Node:__call(...)
    return self:invoke(...)
end

function Node:search(...)
    local keys = {...}
    local function check_key(node)
        for _, k in ipairs(keys) do
            if parent.__tags[k] then return true end
        end
    end

    local function recurse(found, parent)
        if check_key(parent) then found[#found + 1] = parent end
        for _, node in ipairs(self.__node_order) do
            recurse(found, node)
        end
        return found
    end

    return recurse(list(), self)
end

function Node:tag(...)
    self.__tags = {...}
    for i, t in ipairs(self.__tags) do self.__tags[t] = i end
    return self
end

function Node:set_order(order_func)
    local function temporal_order(a, b)
        return self.__children[a] < self.__children[b]
    end

    self.__order_func = order_func or temporal_order
end

function Node:__transform_state()
    local t = self.__transform
    return list(t.pos.x, t.pos.y, t.angle, t.scale.x, t.scale.y)
end

function Node:__transform_changed()
    -- Function that checks if some variable was changed
    -- Used to prevent recomputing the transform matrix on every frame
    local cache = self.__transform.cache or list()
    local state = self:__transform_state()
    for i = 1, 5 do
        if cache[i] ~= state[i] then return state end
    end
end


function Node:update(dt, ...)
    tween.update(dt, self.__group.tween)
    local f, b = self.__threads2update.front, self.__threads2update.back
    self.__threads2update.front = b
    self.__threads2update.back = f

    if not self.__parent then
        -- If at top of tree then clear the mat3stack
        -- Such taht transforms are reset
        mat3stack:clear()
    end

    if self.__motion then
        self:__motion(dt, ...)
    end

    mat3stack:push()

    local next_state = self:__transform_changed()
    if next_state then
        local t = self.__transform
        t.cache = next_state
        t.mat = mat3.translate(t.pos:unpack())
            * mat3.rotate(t.angle)
            * mat3.scale(t.scale:unpack())
    end

    mat3stack:map(mat3.__mul, self.__transform.mat)

    for co, _ in pairs(f) do
        f[co] = nil
        local status, msg = coroutine.resume(co, dt)
        if not status then
            log.error(msg)
        end
    end
    self:__update(dt, ...)

    for _, node in ipairs(self.__node_order) do
        node:update(dt, ...)
    end

    mat3stack:pop()
end

function Node:draw(x, y, r, sx, sy, ...)
    local t = self.__transform
    gfx.push()
    gfx.translate((x or 0) + t.pos.x, (y or 0) + t.pos.y)
    gfx.rotate((r or 0) + t.angle)
    gfx.scale((sx or 1) * t.scale.x, (sy or 1) * t.scale.y)
    if Node.draw_origin and not self.__hidden then
        local lw = gfx.getLineWidth()
        gfx.setLineWidth(5)
        gfx.line(-15, 0, 15, 0)
        gfx.line(0, -15, 0, 15)
        gfx.setLineWidth(lw)
    end

    self:__draworder(0, 0, ...)

    gfx.pop()
end

function Node:hide()
    self.__hidden = true
    return self
end

function Node:show()
    self.__hidden = false
    return self
end

function Node:__draworder(x, y, ...)
    if self.__hidden then return end
    self:__draw(0, 0, ...)
    self:__childdraw(0, 0)
end

function Node:__childdraw(...)
    for _, node in ipairs(self.__node_order) do
        node:draw(0, 0)
    end
end

function Node:adopt(child, name)
    local other = child.__parent
    if other then
        other.__children[child] = nil
        other:__make_order()
    end

    child.__parent = self
    self.__children[child] = love.timer.getTime()
    self:__make_order()

    if name then
        self[name] = child
    end

    if child.on_adopted then child:on_adopted(self, name) end
    return self
end

function Node:orphan(child)
    if child then
        self.__children[child] = nil
        self:__make_order()
        if child.on_orphaned then child:on_orphaned(self) end
    elseif self.__parent then
        local p = self.__parent
        p.__children[self] = nil
        p:__make_order()
        self.__parent = nil
        if self.on_orphaned then self:on_orphaned(p) end
    end


    return self
end

function Node:get_local_transform()
    local next_state = self:__transform_changed()
    if next_state then
        local t = self.__transform
        t.cache = next_state
        t.mat = mat3.translate(t.pos:unpack())
            * mat3.rotate(t.angle)
            * mat3.scale(t.scale:unpack())
    end
    return t.mat
end

function Node:get_full_transform()
    local nodes = list()
    local this = self
    while this do
        nodes[#nodes + 1] = this
        this = this.__parent
    end
    local transforms = nodes:map(function(n) return n:get_local_transform() end)
    local m = mat3.create()
    for i = 1, #transforms do
        m = transforms[i] * m
    end
    return m
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

function Node:join(co)
    self.__group.thread[co] = nil
    event:clear(co)
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

return Node
