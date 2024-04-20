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
---@mdoule "nodeworks.system.map"
local map = require "nodeworks.system.map"


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

end

function painter.push_transform(id)
    local pos = stack.get(nw.component.position, id)
    if pos then love.graphics.translate(pos.x, pos.y) end
    local mirror = stack.get(nw.component.mirror, id)
    if mirror then love.graphics.scale(-1, 1) end
end

function painter.draw_entity(id)
    love.graphics.push("all")

    love.graphics.pop()
end


function painter.draw_tile_layer(layer_id)
    local tile_layer = stack.get(component.tile_layer, layer_id)
    if tile_layer == nil then return end

    love.graphics.push()
    painter.push_transform(layer_id)
    tile_layer:draw()
    love.graphics.pop()
end

function painter.draw_object_layer(layer_id)
    local object_layer = stack.get(component.object_layer, layer_id)
    if object_layer == nil then return end

    local entities = dict.keys(stack.get_table(component.is_on_layer(layer_id)))
    table.sort(entities, painter.compare_entities)

    for _, id in ipairs(entities) do
        painter.draw_entity(id)
    end
end

function painter.draw_image_layer(layer_id)
    local image_layer = stack.get(component.image_layer, layer_id)
    if image_layer == nil then return end
    love.graphics.push()
    painter.push_transform(layer_id)
    image_layer:draw()
    love.graphics.pop()
end

function painter.draw_layer(layer_id)

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