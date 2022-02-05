local nw = require "nodeworks"

local function render_context(w, h)
    w = w or gfx.getWidth()
    h = h or gfx.getHeight()

    return {canvas = gfx.newCanvas(w, h)}
end

local render_system = nw.ecs.system(nw.component.layer_type)

function render_system.on_pushed(world, pool)
    world:singleton():set(render_context)
end

function render_system.on_poped(world, pool)

end

function render_system.on_resize(world, pool, width, height)

end

function render_system.on_entity_added(world, entity, pool)
end

local function read_position(entity)
    local pos = entity % nw.component.position
    if pos then return pos.x, pos.y end
    return 0, 0
end

local function read_scale(entity)
    local scale = entity % nw.component.scale
    if scale then return scale.x, scale.y end
    return 1, 1
end

local function read_rotation(entity)
    return (entity % nw.component.rotation) or 0
end

local function read_body_slice(entity)
    local body_slice_name = entity % nw.component.body_slice
    local slices = entity % nw.component.slices
    if not body_slice_name or not slices then return 0, 0 end
    local b = slices[body_slice_name]
    if not b then return 0, 0 end
    return b.x + b.w * 0.5, b.y + b.h
end

local function read_origin(entity)
    local origin = (entity % nw.component.origin)
    if origin then return origin.x, origin.y end
    return 0, 0
end

local function set_shader(entity)
    local shader = entity % nw.component.shader

    if not shader then
        gfx.setShader()
        return
    end

    gfx.setShader(shader)

    local shader_uniforms = entity % nw.component.shader_uniforms

    if not shader_uniforms then return end

    for field, value in pairs(shader_uniforms) do
        if shader:hasUniform(field) then shader:send(field, value) end
    end
end

local function set_color(entity)
    local color = entity % nw.component.color
    if color then
        gfx.setColor(color[1], color[2], color[3], color[4])
    end
end

local function set_blend_mode(entity)
    local blend_mode = entity % nw.component.blend_mode
    if blend_mode then gfx.setBlendMode(blend_mode) end
end

local function push_transforms(entity)
    gfx.translate(read_position(entity))
    gfx.rotate(read_rotation(entity))
    gfx.scale(read_scale(entity))
end

local function push_state(entity)
    set_color(entity)
    set_shader(entity)
    set_blend_mode(entity)
end

local function draw_args(entity)
    local x, y = read_position(entity)
    local sx, sy = read_scale(entity)
    local r = read_rotation(entity)
    local ox, oy = read_origin(entity)
    local bx, by = read_body_slice(entity)

    return x, y, r, sx, sy, ox + bx, oy + by
end

local drawers = {}

function drawers.image(entity)

    local image = (entity % nw.component.image)

    if not image then return end

    local quad = (entity % nw.component.quad)

    gfx.push("all")
    push_state(entity)
    if quad then
        gfx.draw(image, quad, draw_args(entity))
    else
        gfx.draw(image, draw_args(entity))
    end
    gfx.pop()
end

function drawers.rectangle(entity)
    local draw_mode = entity % nw.component.draw_mode
    local rectangle = entity % nw.component.rectangle

    if not draw_mode or not rectangle then return end

    gfx.push("all")
    push_state(entity)
    push_transforms(entity)
    gfx.rectangle(draw_mode, rectangle:unpack())
    gfx.pop()
end

function drawers.circle(entity)
    local draw_mode = entity % nw.component.draw_mode
    local radius = entity % nw.component.radius
    local segments = entity % nw.component.segments

    if not draw_mode or not circle then return end

    gfx.push("all")
    push_state(entity)
    push_transforms(entity)
    local ox, oy = read_origin(entity)
    gfx.circle(draw_mode, ox, oy, radius, segments)
    gfx.pop()
end

function drawers.mesh(entity)
    local mesh = entity % nw.component.mesh

    if not mesh then return end

    gfx.push("all")
    push_state(entity)
    gfx.draw(mesh, draw_args(entity))
    gfx.pop()
end

function drawers.polygon(entity)
    local polygon = entity % nw.component.polygon
    local draw_mode = entity % nw.component.draw_mode

    if not polygon and not draw_mode then return end

    gfx.push("all")
    push_state(entity)
    push_transforms(entity)
    gfx.polygon(draw_mode, polygon)
    gfx.pop()
end

local function compute_vertical_offset(valign, font, h)
    if valign == "top" then
		return 0
	elseif valign == "bottom" then
		return h - font:getHeight()
    else
        return (h - font:getHeight()) / 2
	end
end

local function get_vertical_offset(entity, shape)
    local valign = entity % nw.component.valign

    return compute_vertical_offset(valign, gfx.getFont(), shape.h)
end

function drawers.text(entity)
    local text = entity % nw.component.text
    local shape = entity % nw.component.rectangle

    if not text or not shape then return end

    local align = entity % nw.component.align

    gfx.push("all")
    push_state(entity)
    push_transforms(entity)
    local dy = get_vertical_offset(entity, shape)
    gfx.printf(text, shape.x, shape.y + dy, shape.w, align)
    gfx.pop()
end

local layer_drawers = {}

function layer_drawers.entitygroup(layer)
    local pool = layer:ensure(nw.component.layer_pool)

    List.foreach(pool, function(entity)
        local drawable = entity % nw.component.drawable
        if not drawable then return end
        if entity % nw.component.hidden then return end
        local f = drawers[drawable]
        if not f then return end
        f(entity)
    end)

    if layer[nw.component.flush_on_draw] then
        layer:set(nw.component.layer_pool)
    end
end

function layer_drawers.fill(layer)
    gfx.clear(1, 1, 1)
end


function render_system.draw(world, pool)
    local context = world:singleton() % render_context
    List.foreach(pool, function(layer)
        local type = layer % nw.component.layer_type
        local f = layer_drawers[type]
        if not f then return end

        gfx.push("all")
        gfx.setCanvas(context.canvas)
        local clear_color = layer % nw.component.clear_color
        if clear_color then
            gfx.clear(clear_color[1], clear_color[2], clear_color[3], clear_color[4])
        else
            gfx.clear(0, 0, 0, 0)
        end
        f(layer)
        gfx.pop()

        gfx.push("all")
        gfx.setColor(1, 1, 1)
        push_state(layer)
        gfx.draw(context.canvas, draw_args(layer))
        gfx.pop()
    end)
end

return render_system
