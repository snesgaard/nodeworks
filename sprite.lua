local animation_state = {}
animation_state.codes = {
    none=0,
    loop=1,
    finish=2,
    next_frame=3
}
animation_state.__index = animation_state

function animation_state.create()
    local this = {
        frames = list(),
        index = -1,
        time = 0,
        speed = 1
    }

    return setmetatable(this, animation_state)
end

function animation_state:start(frames, opt)
    self.frames = frames
    self.index = 1
    self.time = self.frames[self.index].dt
end

function animation_state:get_frame(index)
    index = index or self.index
    return self.frames[index]
end

function animation_state:update(dt, event)
    if self.index > self.frames:size() then
        return "none"
    end

    self.time = self.time - dt * self.speed

    if self.time > 0 then
        return "none"
    end

    self.index = self.index + 1

    if self.index <= self.frames:size() then
        self.time = self.time + self:get_frame().dt
        return "next_frame"
    end

    return "finish"
end

function animation_state:loop()
    self.index = 0
    self:update(0)
    return self
end

function animation_state:has_ended()
    return self.index > self.frames:size()
end

local Sprite = {}
Sprite.__index = Sprite

function Sprite:create(animation_alias, atlas_path)
    atlas = get_atlas(atlas_path)
    self.animation_alias = dict()
    for key, val in pairs(animation_alias) do
        local a = atlas:get_animation(val)
        if not a then
            local msg = string.format("not found %s", key)
            error(msg)
        end
        self.animation_alias[key] = a
    end
    self.stack = list()
    self.state = animation_state.create()
    self.graph = graph.create()
        :branch("color", gfx_nodes.color.dot, 1, 1, 1, 1)
        :branch("texture", gfx_nodes.sprite)

    self.__shake = {
        offset = vec2(),
        freq = 60,
        amp = 10,
        duration = 0.3
    }
end

function Sprite:color()
    return self.graph:find("color")
end

function Sprite:play(key, opt)
    if not self.atlas then
        error("Atlas not set")
    end
    local anime = self.animation_alias[key]
    if not anime then
        error(string.format("animation undefined %s", key))
    end
    self.state:start(anime, key)
end

local function format_key(key)
    if type(key) == "table" then
        return dict(key)
    else
        return dict({key})
    end
end

function Sprite:queue(...)
    local keys = list(...)
    local frames = keys
        :map(function(key)
            -- Create a level-1 copy to make share state can be set outside
            local opt = dict(format_key(key))
            -- O
            opt.frames = self.animation_alias[unpack(opt)]
            if not opt.frames then
                error(string.format("undefined %s", opt[1]))
            end
            return opt
        end)
    local f = frames:tail()
    f.loop = f.loop == nil and true or f.loop

    self._queue = frames:body()
    self.opt = frames:head()
    self.state:start(self.opt.frames)
    self:update_frame(self.state)
end

function Sprite:update_frame(state)
    -- First test gfx
    local frame = state:get_frame()
    self.graph:reset("texture", frame)
    -- Next broadcast which slices where present
    local origin = frame.slices.origin or spatial()
    local center = vec2(origin:center().x, origin.y + origin.h)
    local m = mat3stack:peek()
    local s = self.graph:data("texture").scale

    for key, slice in pairs(frame.slices) do
        slice = slice:move((-center):unpack()):scale(s.x, s.y)
        local c1 = slice:corner()
        local c2 = slice:corner("right", "bottom")
        c1 = m:transform(c1)
        c2 = m:transform(c2)
        local w, h = (c2 - c1):unpack()
        local x, y = c1:unpack()
        slice = spatial(x, y, w, h)
        event(self, join("slice", key), slice)
    end
end

local action = {}

function action.next_frame(self, opt, state)
    self:update_frame(state)
end

function action.finish(self, opt, state)
    if self.opt.loop then
        event(self, "loop", unpack(opt))
        self:update_frame(state:loop())
        return
    end

    event(self, "finish", unpack(opt))
    if self._queue:size() > 0 then
        self.state:start(self._queue:head().frames)
        self:update_frame(self.state)
        return self._queue:head(), self._queue:body()
    end
end

function Sprite:__update(dt)
    if not self.opt then return end
    if self.opt.paused then return end

    local speed = self.opt.speed or 1

    local code = self.state:update(dt * speed)
    local a = action[code] or function() end
    local next_opt, next_queue = a(self, self.opt, self.state)
    if next_opt then
        self.opt = next_opt
    end
    if next_queue then
        self._queue = next_queue
    end
end

function Sprite:__draw()
    if not self.hidden then
        gfx.push()
        gfx.translate(self.__shake.offset:unpack())
        self.graph:traverse()
        gfx.pop()
    end
end

local function do_shake(self, shake)
    local time = shake.duration
    while time > 0 do
        local a = shake.amp * (time / shake.duration)
        local f = shake.freq * time
        shake.offset = vec2(math.cos(f) * a, 0)
        time = time - event:wait("update")
    end

    shake.offset = vec2()
end

function Sprite:shake()
    local shake = self.__shake
    self:fork(do_shake, shake)
end

function Sprite:offset(animation, from, to)
    local frames = self.animation_alias[animation]
    if not frames then
        error("Animation undefined %s", animation)
    end

    local f = frames:find(function(f)
        return f.slices[from] and f.slices[to]
    end)

    if not f then
        error(
            "No frames with both %s and %s in animation %s",
            from, to, animation
        )
    end

    local from_slice = f.slices[from]
    local to_slice = f.slices[to]

    -- y coordinate is flipped to map aseprite coordinate system to LOVE's
    -- Scale to match the sprites scaling
    local s = self.graph:data("texture").scale
    return (to_slice:center() - from_slice:center()) * vec2(1, -1) * s
end

function Sprite:attack_offset()
    return self:offset("attack", "origin", "attack")
end

function Sprite:cast_offset()
    return self:offset("cast", "origin", "cast")
end

function Sprite:shape()
    local f = self.state:get_frame()
    local q = f.quad
    local x, y, w, h = q:getViewport()
    local s = self.graph:data("texture").scale
    local p = self.__transform.pos
    return spatial(-w * 0.5, -h, w, h):scale(s.x, s.y):move(p:unpack())
end

return Sprite
