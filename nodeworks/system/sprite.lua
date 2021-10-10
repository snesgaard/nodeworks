local nw = require "nodeworks"

local system = nw.ecs.system()

function system.draw(entity, x, y)
    if not entity then return end
    local sprite = entity[components.sprite]
    if not sprite then return end
    local image = sprite[components.image]
    local args = sprite[components.draw_args]

    x = x or 0
    y = y or 0

    gfx.setColor(1, 1, 1)
    gfx.push()

    local position = entity[components.position] or components.position()
    gfx.translate(position.x + x, position.y + y)

    local slices = sprite[components.slices]
    local body_key = sprite[components.body_slice]
    local body_slice = slices[body_key] or spatial()
    local c = body_slice:center()
    local ox, oy = args.ox + c.x, args.oy + c.y
    local sx = entity[components.mirror] and -1 or 1

    if sprite[components.visible] then
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
