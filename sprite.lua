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

    self.__shake = {
        offset = vec2(),
        freq = 60,
        amp = 10,
        duration = 0.3
    }
    self.transform = transform()
end

function Sprite:get_animation(key)
    return self.animation_alias[key]
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
    event(self, "queuing", keys)
end

function Sprite:play(opt)
    local opt = format_key(opt)
    if self:is_playing(unpack(opt)) then return end
    return self:queue(opt)
end

function Sprite:is_playing(key)
    if not self.opt then return false end
    return self.opt[1] == key
end

function Sprite:update_frame(state)
    -- First test gfx
    local frame = state:get_frame()
    if self.on_root_motion then
        self.on_root_motion(self, frame.root_motion)
    end
    -- Next broadcast which slices where present
    local origin = frame.slices[Sprite.default_origin] or spatial()

    local transforms = nil
    local relative_slices = dict()
    for key, slice in  pairs(frame.slices) do
        local path = join("slice", key)
        local origin_slice = slice:relative(origin)
        relative_slices[key] = origin_slice
        event(self, path, origin_slice)

        local global_path = join("slice", key, "global")

        if event:is_active(self, global_path) then
            transforms = transforms or self:rootpath()
            local global_slice = transforms:reduce(
                function(slice, node)
                    if not node.transform then
                        return slice
                    else
                        return node.transform:forward(slice)
                    end
                end,
                origin_slice
            )
            event(self, global_path, global_slice)
        end
    end

    if self.on_slice_update then
        self.on_slice_update(relative_slices)
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

function Sprite:update(dt, args)
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

function Sprite:draw(...)
    if not self.hidden then
        gfx.push()
        gfx.translate(self.__shake.offset:unpack())
        --self.graph:traverse()
        local f = self.state:get_frame()
        if f then f:draw(Sprite.default_origin, ...) end
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
    -- TODO Repalce with actual sprite scale
    local s = self.transform.scale
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
    -- TODO Repalce with actual sprite scale
    local s = self.transform.scale
    local p = self.__transform.pos
    return spatial(-w * 0.5, -h, w, h):scale(s.x, s.y):move(p:unpack())
end

function Sprite:get_animation(key)
    return self.animation_alias[key]
end

Sprite.default_origin = "body"

return Sprite
