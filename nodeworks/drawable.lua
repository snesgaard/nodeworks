local drawables = {}

function drawables.push_color(entity, opacity)
    local color = entity % nw.component.color
    local opacity = opacity or 1
    if color then
        local r, g, b, a = color[1], color[2], color[3], color[4]
        gfx.setColor(r, g, b, (a or 1) * opacity)
    else
        gfx.setColor(1, 1, 1, opacity)
    end
end

function drawables.push_font(entity)
    local font = entity % nw.component.font
    if not font then return end
    gfx.setFont(font)
end

function drawables.push_state(entity)
    drawables.push_color(entity)
    drawables.push_font(entity)
end

function drawables.push_transform(entity)
    local pos = entity:get(nw.component.position)
    if pos then gfx.translate(pos.x, pos.y) end
    local mirror = entity:get(nw.component.mirror)
    if mirror then gfx.scale(-1, 1) end
end

function drawables.animation(entity)
    gfx.push()
    drawables.push_transform(entity)
    drawables.push_state(entity)

    local frame = nw.system.animation():get(entity)
    if frame then
        frame:draw("body")
    else
        gfx.rectangle("fill", -5, -10, 10, 10)
    end

    gfx.pop()
end

function drawables.body(entity)
    local body = entity % nw.component.hitbox
    if not body then return end

    gfx.push("all")
    drawables.push_transform(entity)
    drawables.push_state(entity)

    drawables.push_color(entity, 0.5)
    gfx.rectangle("fill", body:unpack())
    drawables.push_color(entity)
    gfx.rectangle("line", body:unpack())

    gfx.pop()
end

function drawables.particles(entity)
    local particles = entity % nw.component.particles
    if not particles then return end

    gfx.push("all")
    drawables.push_transform(entity)
    drawables.push_state(entity)
    gfx.draw(particles, 0, 0)
    gfx.pop()
end

return drawables
