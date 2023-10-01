local nw = require "nodeworks"
local stack = nw.ecs.stack
local drawables = {}

function drawables.push_color(id, opacity)
    local color = stack.get(nw.component.color, id)
    local opacity = opacity or 1
    if color then
        local r, g, b, a = color[1], color[2], color[3], color[4]
        gfx.setColor(r, g, b, (a or 1) * opacity)
    else
        gfx.setColor(1, 1, 1, opacity)
    end
end

function drawables.push_font(id)
    local font = stack.get(nw.component.font, id)
    if not font then return end
    gfx.setFont(font)
end

function drawables.push_state(entity)
    drawables.push_color(entity)
    drawables.push_font(entity)
end

function drawables.push_transform(id)
    local pos = stack.get(nw.component.position, id)
    if pos then gfx.translate(pos.x, pos.y) end
    local mirror = stack.get(nw.component.mirror, id)
    if mirror then gfx.scale(-1, 1) end
    local scale = stack.get(nw.component.scale, id)
    if scale then gfx.scale(scale.x, scale.y) end
end

function drawables.hitbox(id)
    local x, y, w, h = collision.get_world_hitbox(id)
    if not x then return end
    gfx.push("all")
    drawables.push_state(id)
    gfx.rectangle("line", x, y, w, h)
    gfx.pop()
end

return drawables
