local Sprite = {}

function Sprite:create()
    self._queue = list()
    self._animation_alias = dict()
    self._graph = graph.create()
        :branch("color", gfx_nodes.set, 1, 1, 1, 1)
        :leaf("sprite", gfx_nodes.sprite)
end

function Sprite:queue(name, opt)
    self._queue = self._queue:insert({name, opt})
    return self
end

function Sprite:pop()
    local next = self._queue:head()
    if not next then return end
    self._queue = self._queue:body()
    return self:play(unpack(next))
end

function Sprite:play(name, opt)
    local animation = self._animation_alias[name]
    if not animation then
        error(string.format("Unknown animation %s", name))
    end
    self._animation = animation
    self._index = 0
    self._time = 0
    self:_set_frame()
    return self
end

function Sprite:__update(dt)
    if not self._animation then return end
    if self._paused then return end
    if self._index > self._animation:size() then return end

    self._time = self._time - dt * self._speed
    if self._time > 0 then
        self._time = time
        return
    end

    local index = self._index + 1
    if index < self.animation:size() then
        self._index = index
        self:_set_frame()
        return self:__update(0)
    end

    if self._animation_opt.loop then
        event(self, "loop")
        self._index = 0
        return self:__update(0)
    else
        event(self, "finish")
        -- If nothing else ont he queue
        -- Simply set all to dead
        if not self:pop() then
            self._animation = nil
        end
    end
end

function Sprite:_set_frame(frame)
    local function get_frame()
        if type(frame) == "table" then
            return frame
        elseif type(frame) == "number" then
            return self._animations[frame]
        else
            return self._animations[self._index]
        end
    end

    local frame = get_frame()
    local node = self._graph:find("sprite")
    node.image = frame.sheet
    node.quad = frame.quad
    self._time = self._time + frame.dt
    -- TODO: Set offset
    -- TODO: Advertise hitboxes / slices
end

return Sprite
