local function getCellRect(world, cx,cy)
  local cellSize = world.cellSize
  local l,t = world:toWorld(cx,cy)
  return l,t,cellSize,cellSize
end

local function get_color(key)
    if type(key) ~= "table" then
        return 0, 1, 0
    end
    if key[components.body] then
        return 0, 0, 1
    else
        return 1, 0, 0
    end
end

local function draw_world(world)
    local cellSize = world.cellSize
    local font = love.graphics.getFont()
    local fontHeight = font:getHeight()
    local topOffset = (cellSize - fontHeight) / 2
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

    for key, rects in pairs(world.rects) do
        local r, g, b = get_color(key)
        gfx.setColor(r, g, b)
        gfx.rectangle("line", rects.x, rects.y, rects.w, rects.h)
        gfx.setColor(r, g, b, 0.3)
        gfx.rectangle("fill", rects.x, rects.y, rects.w, rects.h)
    end
    gfx.setColor(1, 1, 1)
end

local function world_draw_from_pool(pool)
    local worlds_drawn = {}

    for _, entity in ipairs(pool) do
        local world = entity[components.bump_world]
        if not worlds_drawn[world] then
            worlds_drawn[world] = true
            draw_world(world)
        end
    end
end

local function draw_coordinate_systems(pool)
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

local function get_transformed_body(entity, body)
    body = body or entity[components.body]
    local pos = entity[components.position] or components.position()
    if body then
        return body:move(pos:unpack())
    end
end


local system = ecs.system(components.body, components.bump_world)

function system:on_entity_added(entity)
    -- Give it a unique identifer
    local world = entity[components.bump_world]
    local pos = entity[components.position] or components.position()
    local body = entity[components.body]
    world:add(entity, body:move(pos:unpack()):unpack())
end

function system:on_entity_removed(entity)
    self.__uuid = self.__uuid or {}
end

function system:update(dt)
    for _, entity in ipairs(self.pool) do
        local world = entity[components.bump_world]
        local pos = entity[components.position] or components.position()
        local body = entity[components.body]
        local next_body = body:move(pos:unpack())
        local ax, ay, cols = world:move(entity, next_body.x, next_body.y)
        local dx, dy = ax - next_body.x, ay - next_body.y
        entity:update(components.position, pos.x + dx, pos.y + dy)

        for _, c in ipairs(cols) do
            self.world:event("on_collision", c)
        end
    end
end

function system.show(enabled)
    system.__debug_draw = true
    return system
end

function system.hide()
    system.__debug_draw = false
    return system
end

function system:draw()
    if not system.__debug_draw then return end

    world_draw_from_pool(self.pool)
    draw_coordinate_systems(self.pool)
end

function system.can_resize(entity, body)

end

function system.resize(entity, body)
    local body = entity[components.body]
    local world = entity[components.world]
    if not body or not world then return false end
    if not system.can_resize(entity, body) then return false end

end

return system
