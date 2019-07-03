local rng = love.math.random

local Sprite = {}

function Sprite.create(this, atlas)
    this.atlas = atlas
    this.origin = 'origin'
    this.__mirror = 1
    this.color = {1, 1, 1, 1}
    this.on_user = event()
    this.on_loop = event()
    this.on_hitbox = event()
    this.__offset = offset or {}

    return this
end

function Sprite:__draw(x, y)
    if not self.__draw_frame then return end

    gfx.setColor(unpack(self.color or {1, 1, 1}))
    local amp = self.shake_amp
    local phase = self.shake_phase

    x = (x or 0) + (amp > 0 and (math.sin(phase) * amp) or 0)
    y = (y or 0)
    sx = self.mirror
    self.__draw_frame:draw(self.origin or "", x, y, 0, sx, 1)
end


function Sprite:set_origin(origin)
    self.origin = origin
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
