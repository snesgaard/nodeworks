local debug = {}

local function getCellRect(world, cx,cy)
  local cellSize = world.cellSize
  local l,t = world:toWorld(cx,cy)
  return l,t,cellSize,cellSize
end

local function get_color(key)
    if type(key) ~= "table" then
        return 0, 1, 0
    end
    if key[nw.component.body] then
        return 0, 0, 1
    else
        return 1, 0, 0
    end
end

function debug.draw_world(world, draw_cells)
    local cellSize = world.cellSize
    local font = love.graphics.getFont()
    local fontHeight = font:getHeight()
    local topOffset = (cellSize - fontHeight) / 2
    if draw_cells then
        for cy, row in pairs(world.rows) do
            for cx, cell in pairs(row) do
                local l,t,w,h = getCellRect(world, cx,cy)
                local intensity = cell.itemCount * 12 + 16
                love.graphics.setColor(255,255,255,intensity)
                love.graphics.rectangle('line', l,t,w,h)
                love.graphics.setColor(255,255,255, 64)
                love.graphics.printf(cell.itemCount, l, t+topOffset, cellSize, 'center')
                love.graphics.setColor(255,255,255,10)
                love.graphics.rectangle('line', l,t,w,h)
            end
        end
    end

    for key, rects in pairs(world.rects) do
        local r, g, b = get_color(key)
        gfx.setColor(r, g, b)
        gfx.rectangle("line", rects.x, rects.y, rects.w, rects.h)
        gfx.setColor(r, g, b, 0.3)
        gfx.rectangle("fill", rects.x, rects.y, rects.w, rects.h)
    end
    gfx.setColor(1, 1, 1)
end

function debug.world_draw_from_pool(pool)
    local worlds_drawn = {}

    for _, entity in ipairs(pool) do
        local world = entity[components.bump_world]
        if not worlds_drawn[world] then
            worlds_drawn[world] = true
            draw_world(world)
        end
    end
end

function debug.draw_coordinate_systems(pool)
    for _, entity in ipairs(pool) do
        local p = entity[components.position]
        if p then
            local x_min = vec2(-10, 0) + p
            local x_max = vec2(10, 0) + p
            local y_min = vec2(0, -10) + p
            local y_max = vec2(0, 10) + p
            gfx.setColor(1, 0, 0)
            gfx.line(x_min.x, x_min.y, x_max.x, x_max.y)
            gfx.setColor(0, 1, 0)
            gfx.line(y_min.x, y_min.y, y_max.x, y_max.y)
        end
    end
end

return debug
