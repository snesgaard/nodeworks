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

function drawables.tiled_layer(id)
    local layer = stack.get(nw.component.tiled_layer, id)
    if not layer then return end

    gfx.push("all")
    
    drawables.push_state(id)
    drawables.push_transform(id)

    layer:draw()

    gfx.pop()
end

function drawables.scrolling_texture(id)
    local image = stack.get(nw.component.image, id)
    if not image then return end

    local wrap_mode = stack.get(nw.component.wrap_mode, id)
    
    image:setWrap(
        wrap_mode.repeatx and "repeat" or "clampzero",
        wrap_mode.repeaty and "repeat" or "clampzero"
    )

    gfx.push("all")
    
    drawables.push_state(id)
    drawables.push_transform(id)
    
    local lx, ly = gfx.transformPoint(0, 0)
    local ux, uy = gfx.transformPoint(image:getWidth(), image:getHeight())

    local w, h = math.abs(lx - ux), math.abs(ly - uy)
    
    
    local quad = gfx.newQuad(
        -lx, -ly,
        gfx.getWidth(), gfx.getHeight(),
        w, h
    )
    
    local sx = gfx.getWidth() / image:getWidth()
    local sy = gfx.getHeight() / image:getHeight()

    local sx, sy = 1, 1

    gfx.origin()
    gfx.draw(image, quad, 0, 0, 0, sx, sy)

    gfx.pop()
end

return drawables
