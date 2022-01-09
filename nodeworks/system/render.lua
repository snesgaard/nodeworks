local nw = require "nodeworks"

local function render_context(w, h)
    w = w or gfx.getWidth()
    h = h or gfx.getHeight()

    return {canvas = gfx.newCanvas(w, h)}
end

local render_system = nw.ecs.system(
    nw.component.layer_pool, nw.component.layer_type, nw.component.priority
)

function render_system.on_pushed(world, pool)
    world:singleton():set(render_context)
end

function render_system.on_poped(world, pool)

end

function render_system.on_resize(world, pool, width, height)

end

function render_system.on_entity_added(world, entity, pool)
    local function cmp_layer_for_sort(a, b)
        return (a % nw.component.priority) < (b % nw.component.priority)
    end
    pool:sort(cmp_layer_for_sort)
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
    if color then gfx.setColor(color) end
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
    push_transforms(entity)
    set_color(entity)
    set_shader(entity)
    set_blend_mode(entity)
end

local function draw_args(entity)
    local x, y = read_position(entity)
    local sx, sy = read_scale(entity)
    local r = read_rotation(entity)
    local ox, oy = read_origin(entity)

    return x, y, r, sx, sy, ox, oy
end

local drawers = {}

function drawers.image(entity)

    local image = (entity % nw.component.image)

    if not image then return end

    local quad = (entity % nw.component.quad)

    gfx.push("all")
    set_shader(entity)
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
    gfx.circle(draw_mode, circle, 0, 0, radius, segments)
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

local layer_drawers = {}

function layer_drawers.objectgroup(entity)
    local drawable = entity % nw.component.drawable
    if not drawable then return end
    local f = drawers[drawable]
    if not f then return end
    f(entitiy)
end


function render_system.draw(world, pool)
    local canvas = world:singleton() % render_context

    List.foreach(pool, function(layer)
        local type = layer % nw.component.layer_type
        local f = layer_drawers[type]
        if f then return end

        gfx.push("all")
        gfx.setCanvas(canvas)
        gfx.clear(layer % nw.component.clear_color)
        f(layer)
        gfx.pop()

        gfx.push("all")
        push_state(layer)
        gfx.draw(layer, draw_args(entity))
        gfx.pop()
    end)
end

return render_system
