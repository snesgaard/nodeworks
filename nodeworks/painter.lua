local NULL_POS = vec2()
local ONE_SCALE = vec2(1, 1)

local function compare_drawers(a, b)
    local layer_a = stack.get(nw.component.layer, a) or 0
    local layer_b = stack.get(nw.component.layer, b) or 0
    if layer_a ~= layer_b then return layer_a < layer_b end

    local pos_a = stack.get(nw.component.position, a) or NULL_POS
    local pos_b = stack.get(nw.component.position, b) or NULL_POS

    if 1e-5 < math.abs(pos_a.x - pos_b.x) then return pos_a.x < pos_b.x end

    return pos_a.y < pos_b.y
end

local function get_camera_position(camera_id)
    if not camera_id then return 0, 0 end
    local p = stack.get(nw.component.position, camera_id)
    if not p then return 0, 0 end
    return p.x, p.y
end

local function get_camera_scale(camera_id)
    if not camera_id then return 1, 1 end
    local s = stack.get(nw.component.scale, camera_id)
    if not s then return 1, 1 end
    return s.x, s.y
end

local function get_camera_origin(camera_id)
    local ox, oy = gfx.getWidth() / 2, gfx.getHeight() / 2
    if not camera_id then return ox, oy end
    local o = stack.get(nw.component.origin, camera_id)
    if not o then return ox, oy end
    return o.x, o.y
end

local function get_parallax(id)
    local p = stack.get(nw.component.parallax, id)
    if not p then return 1, 1 end
    return p.x, p.y 
end

local painter = {}

function painter.get_drawables_in_order()
    local drawables = stack.get_table(nw.component.drawable)
    local order = drawables:keys():sort(compare_drawers)
    return order, drawables
end

function painter.debug_draw()

end

function painter.draw(camera_id)
    local order, drawables = painter.get_drawables_in_order()

    local x, y = get_camera_position(camera_id)
    local sx, sy = get_camera_scale(camera_id)
    local ox, oy = get_camera_origin(camera_id)

    gfx.push()

    gfx.translate(ox, oy)
    gfx.scale(sx, sy)

    for _, id in ipairs(order) do
        local f = drawables[id]
        if not stack.get(nw.component.hidden, id) and f then
            local px, py = get_parallax(id)
            gfx.push()
            gfx.translate(-x * px, -y * py)
            f(id)
            gfx.pop()
        end

    end

    gfx.translate(-x, -y)
    painter.debug_draw()
    gfx.pop()
end

return painter