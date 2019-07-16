local rng = love.math.random

local Sprite = {}

function Sprite.create(this)
    this.__origin = 'origin'
    this.__mirror = 1
    this.__color = {1, 1, 1, 1}
    this.__offset = vec2(0, 0)
    this.__center = vec2(0, 0)

    return this
end

Sprite.origin = attribute("__origin")
Sprite.color = attribute("__color")
Sprite.quad = attribute("__quad")
Sprite.image = attribute("__image")
Sprite.offset = attribute("__offset")
Sprite.center = attribute("__center")

function Sprite:__draw(x, y)
    if not self.__quad or not self.__image then return end

    gfx.setColor(unpack(self.__color or {1, 1, 1}))

    x = (x or 0)
    y = (y or 0)
    sx = self.__mirror
    --self.__draw_frame:draw(self.__origin or "", x, y, 0, sx, 1)

    gfx.draw(
        self.__image, self.__quad,
        x, y, 0, sx, 1, -self.__offset.x + self.__center.x,
        -self.__offset.y + self.__center.y
    )
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
