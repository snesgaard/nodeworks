local rng = love.math.random

local Sprite = {}

function Sprite.create(this, atlas, animes)
    this.time = 0
    this.atlas = atlas
    this.__states = {}
    this.active = nil
    this.origin = 'origin'
    this.__mirror = 1
    this.color = {1, 1, 1, 1}
    this.on_user = event()
    this.on_loop = event()
    this.on_hitbox = event()
    this.shake_amp = 0
    this.shake_phase = 0
    this.__hitbox_cache = {}

    this.__transform.scale = vec2(2, 2)

    for k, v in pairs(animes or {}) do
        this:register(k, v)
    end

    return this
end

function Sprite:__draw(x, y)
    if not self.__draw_frame then return end
    
    gfx.setColor(unpack(self.color or {1, 1, 1}))
    local amp = self.shake_amp
    local phase = self.shake_phase

    x = (x or 0) + math.sin(phase) * amp
    y = (y or 0)
    sx = self.mirror
    self.__draw_frame:draw(self.origin or "", x, y, 0, sx, 1)
end

function Sprite:on_frame_progress() end
function Sprite:on_frame_motion() end

function Sprite:__get_motion(frames, frame_index, origin, mirror, scale)
    origin = origin or self.origin
    mirror = mirror or self.mirror
    scale = scale or self.__transform.scale

    local prev_frame = frames[frame_index - 1]
    local next_frame = frames[frame_index]

    if not prev_frame or not next_frame then
        return vec2(0, 0)
    end

    local prev_pos = prev_frame.slices[origin]
    local next_pos = next_frame.slices[origin]

    local function get_center(pos)
        if not pos then
            return vec2(0, 0)
        else
            return vec2(pos.x + pos.w * 0.5, pos.y + pos.h * 0.5)
        end
    end

    local motion = get_center(next_pos) - get_center(prev_pos)

    return motion * mirror * scale
end

function Sprite:play(dt, frame_key, init_frame)
    init_frame = init_frame or 1
    local frames = self.atlas:get_animation(frame_key)
    for i = init_frame, frames:size() do
        local f = frames[i]
        self.__draw_frame = f
        self.time = self.time + f:get_dt()

        local hitboxes = self:get_hitboxes()
        self.hitboxes = hitboxes
        self.on_hitbox(hitboxes)
        self.on_frame_progress(self, i, f, hitboxes)

        local motion = self:__get_motion(
            frames, i, self.origin, self.__mirror
        )
        self.on_frame_motion(self, motion)

        while self.time > 0 do
            _, dt = coroutine.yield()
            self.time = self.time - dt
        end

    end
    self.on_loop()

    return dt
end

function Sprite:hide()
    timer.tween(
        0.4,
        {
            [self.color] = {[4] = 0}
        }
    )
end

function Sprite:show()
    timer.tween(
        0.4,
        {
            [self.color] = {[4] = 1}
        }
    )
end

function Sprite:get_hitboxes(x, y)
    if not self.__draw_frame then return end

    x = (x or 0) + self.__transform.pos.x
    y = (y or 0) + self.__transform.pos.y

    local frame = self.__draw_frame

    local function get_center()
        local origin = frame.slices[self.origin]
        if origin then
            return origin:center():unpack()
        else
            return 0, 0
        end
    end

    local cx, cy = get_center()

    local ret = dict()

    for key, box in pairs(frame.slices) do
        ret[key] = spatial(box.x, box.y, box.w, box.h)
            :move(-cx, -cy)
            :scale(self.scale, self.scale)
            :map(function(s)
                if self.__mirror < 0 then
                    return s:hmirror(0, 0)
                else
                    return s
                end
            end)
            :move(x, y)
    end

    return ret
end

function Sprite:shake(strong)
    if self.shake_tween then
        self.shake_tween:remove()
    end
    local s = rng() > 0.5 and 1 or -1
    self.shake_amp = strong and 15 or 5
    self.shake_phase = s * math.pi * 8
    self.shake_tween = timer.tween(
        0.4,
        {
            [self.shake_data] = {amp = 0, phase = 0},
        }
    )
end

function Sprite:loop(dt, frame_key, init_frame)
    while true do
        dt = self:play(dt, frame_key, init_frame)
        init_frame = 1
    end
end

function Sprite:register(key, animation)
    self.__states[key] = animation
end

function Sprite:set_animation(a, ...)
    local s = self.__states[a]
    if s then
        self.time = 0
        local prev_state = self.state
        self.state = s
        self.active = coroutine.wrap(
            function(sprite, dt)
                s(sprite, dt, prev_state)
                self.active = nil
            end
        )
        return self
    elseif a then
        log.warn("Animation %s was not found", a)
        return self:set_animation(...)
    else
        return self
    end
end

function Sprite:set_origin(origin)
    self.origin = origin
end

function Sprite:__update(dt)
    if self.active then
        self.active(self, dt)
    end
end

function Sprite:attack_offset()
    return 0
end

function Sprite:set_color(r, g, b, a)
    self.color = {r or 1, g or 1, b or 1, a or 1}
    return self
end

function Sprite:set_mirror(val)
    local prev_mirror = self.__mirror

    if not val then
        self.__mirror = -self.__mirror
    else
        self.__mirror = val
    end

    if prev_mirror ~= self.__mirror then
        local hitboxes = self:get_hitboxes()
        self.on_hitbox(hitboxes)
    end
end

return Sprite
