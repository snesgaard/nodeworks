---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.core.dict"
local dict = require "nodeworks.core.dict"
---@module "nodeworks.core.misc"
local misc = require "nodeworks.core.misc"
---@module "nodeworks.system.camera"
local camera = require "nodeworks.system.camera"
---@module "nodeworks.system.map"
local map = require "nodeworks.system.map"
---@module "nodeworks.system.time"
local time = require "nodeworks.system.time"


local painter = {}

---@param a Id
---@param b Id
---@return boolean b_greater_than_a
function painter.compare_entities(a, b)
    local pos_a = stack.get_or_default(component.position, a, 0, 0)
    local pos_b = stack.get_or_default(component.position, b, 0, 0)

    local dx = pos_b.x - pos_a.x 
    local dy = pos_b.y - pos_a.y

    if 1 < math.abs(dx) then return dx > 0 end

    return dy > 0
end

function painter.push_state(id)
    local color = stack.get(component.color, id)
    if color then
        love.graphics.setColor(color[1], color[2], color[3], color[4])
    end
end

function painter.push_transform(id)
    local pos = stack.get(component.position, id)
    if pos then love.graphics.translate(pos.x, pos.y) end
    local mirror = stack.get(component.mirror, id)
    if mirror then love.graphics.scale(-1, 1) end
end

function painter.draw_tile_layer(layer_id)
    local tile_layer = stack.get(component.tile_layer, layer_id)
    if tile_layer == nil then return end

    love.graphics.push()
    painter.push_transform(layer_id)
    tile_layer:draw()
    love.graphics.pop()
end
---@param layer_id Id
---@return Id[]
function painter.draw_object_layer(layer_id)
    local object_layer = stack.get(component.object_layer, layer_id)
    if object_layer == nil then return {} end

    local layer_index = stack.get(component.layer, layer_id)

    if layer_index == nil then return {} end
    
    local entities = stack.get_table(component.is_on_layer(layer_index))
    local entity_draw_order = dict.keys(entities)
    table.sort(entity_draw_order, painter.entity_draw_order_compare)

    for _, id in ipairs(entity_draw_order) do
        love.graphics.push("all")
        painter.push_transform(id)
        painter.push_state(id)
        painter.draw_entity(id)
        love.graphics.pop()
    end

    return entity_draw_order
end

local null_pos = component.position(0, 0)

---@param a Id
---@param b Id
---@return boolean
function painter.entity_draw_order_compare(a,  b)
    local pos_a = stack.get(component.position, a) or null_pos
    local pos_b = stack.get(component.position, b) or null_pos

    local dx = pos_b.x - pos_a.x
    if math.abs(dx) > 1 then return dx > 0 end

    local dy = pos_b.y - pos_a.y
    return dy > 0
end

---@param id Id
function painter.draw_entity(id)
    local frame = stack.get(component.frame, id)
    if frame then frame:draw("body") end

    local draw_rect = stack.get(component.draw_rect, id)
    if draw_rect then
        love.graphics.rectangle(
            draw_rect.mode,
            draw_rect.shape.x, draw_rect.shape.y, draw_rect.shape.w, draw_rect.shape.h,
            draw_rect.round
        )
    end
    
    local p = stack.get(component.particles, id)
    if p then love.graphics.draw(p, x, y) end
end

function painter.get_scroll_squad()
    painter.__scroll_quad = painter.__scroll_quad or love.graphics.newQuad(0, 0, 1, 1, 1, 1)
    return painter.__scroll_quad
end


function painter.draw_image_layer(layer_id)
    local image_layer = stack.get(component.image_layer, layer_id)
    if image_layer == nil then return end

    local image = image_layer.image
    local wrap_mode = {
        repeatx = true,
        repeaty = false
    }
    image:setWrap(
        wrap_mode.repeatx and "repeat" or "clampzero",
        wrap_mode.repeaty and "repeat" or "clampzero"
    )

    love.graphics.push("all")
    
    painter.push_transform(layer_id)
    
    local lx, ly = love.graphics.transformPoint(0, 0)
    local ux, uy = love.graphics.transformPoint(image:getWidth(), image:getHeight())

    local w, h = math.abs(lx - ux), math.abs(ly - uy)
    
    local scroll_quad = painter.get_scroll_squad()
    local hscroll = image_layer.properties.horizontal_time_scroll or 0
    scroll_quad:setViewport(
        -lx + time.clock() * hscroll, -ly,
        love.graphics.getWidth(), love.graphics.getHeight(),
        w, h
    )

    local sx, sy = 1, 1

    love.graphics.origin()
    love.graphics.draw(image, scroll_quad, 0, 0, 0, sx, sy)

    love.graphics.pop()
end

function painter.draw_layer(layer_id)
    if stack.get(component.is_hidden, layer_id) then return end

    love.graphics.push("all")
    painter.push_state(layer_id)

    painter.draw_tile_layer(layer_id)
    painter.draw_object_layer(layer_id)
    painter.draw_image_layer(layer_id)

    love.graphics.pop()
end

function painter.draw(camera_id)
    local camera_pos, camera_scale = camera.get_transform(camera_id)
    for _, layer_id in map.view_layers() do
        local parallax = stack.get_or_default(component.parallax, layer_id, 1, 1)

        love.graphics.push("all")

        camera.push_transform(camera_pos, camera_scale, parallax)
        painter.draw_layer(layer_id)

        love.graphics.pop()
    end
end

return painter