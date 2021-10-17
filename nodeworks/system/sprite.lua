local nw = require "nodeworks"

local system = nw.ecs.system()

function system.draw(entity, x, y)
    if not entity then return end
    local sprite = entity[nw.component.sprite]
    if not sprite then return end
    local image = sprite[nw.component.image]
    local args = sprite[nw.component.draw_args]

    x = x or 0
    y = y or 0

    gfx.setColor(1, 1, 1)
    gfx.push()

    local position = entity[nw.component.position] or nw.component.position()
    gfx.translate(position.x + x, position.y + y)

    local slices = sprite[nw.component.slices]
    local body_key = sprite[nw.component.body_slice]
    local body_slice = slices[body_key] or spatial()
    local c = body_slice:center()
    local ox, oy = args.ox + c.x, args.oy + c.y
    local sx = entity[nw.component.mirror] and -1 or 1

    if sprite[nw.component.visible] then
        if image.image and image.quad then
            gfx.draw(
                image.image, image.quad,
                args.x, args.y, args.r, sx * args.sx, args.sy, ox, oy
            )
        elseif image.image then
            gfx.draw(
                image.image,
                args.x, args.y, args.r, sx * args.sx, args.sy, ox, oy
            )
        end
    end

    gfx.pop()
end

return system
