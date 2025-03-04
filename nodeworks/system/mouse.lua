local event_type = require "nodeworks.event_type"
local event = require "nodeworks.system.event"
local tf = require "nodeworks.system.tf"
local component = require "nodeworks.component"
local stack = require "nodeworks.ecs.stack"
local collision = require "nodeworks.system.collision"
local camera = require "nodeworks.system.camera"
local vec2 = require "nodeworks.core.vec2"
local spatial = require "nodeworks.core.spatial"

local mouse = {}

function mouse.get_screen_size()
    return love.graphics.getWidth(), love.graphics.getHeight()
end

function mouse.mouse_in_world(camera_id, x, y)
    local t = camera.get_transform_matrix(
        stack.get(component.position, camera_id),
        stack.get(component.scale, camera_id),
        vec2(mouse.get_screen_size())
    )

    return t:inverse():transformPoint(x, y)
end

function mouse.can_press_entity(id)
    return stack.get(component.is_mouse_interactable, id)
end

---@param x number
---@param y number
---@param button integer
function mouse.mousepressed(x, y, button)
    for camera_id, _ in stack.view_table(component.is_camera) do
        local wx, wy = mouse.mouse_in_world(camera_id, x, y)
        local clicked_entities = collision.query(spatial(wx, wy, 1, 1), mouse.can_press_entity)
        for _, id in ipairs(clicked_entities) do
            event.emit(event_type.entity_mousepressed, id, button)
        end
    end
end

function mouse.mousemoved(x, y)
    stack.destroy_table(component.is_mouse_hovering)

    for camera_id, _ in stack.view_table(component.is_camera) do
        local wx, wy = mouse.mouse_in_world(camera_id, x, y)
        local clicked_entities = collision.query(spatial(wx, wy, 1, 1), mouse.can_press_entity)
        
        for _, id in ipairs(clicked_entities) do
            stack.set(component.is_mouse_hovering, id)
        end
    end
end

function mouse.mousereleased(x, y, button)
    for camera_id, _ in stack.view_table(component.is_camera) do
        local wx, wy = mouse.mouse_in_world(camera_id, x, y)
        local clicked_entities = collision.query(spatial(wx, wy, 1, 1), mouse.can_press_entity)
        
        for _, id in ipairs(clicked_entities) do
            event.emit(event_type.entity_mousereleased, id, button)
        end
    end
end

function mouse.spin()
    for _, event in event.view(event_type.mousepressed) do
        mouse.mousepressed(event.x, event.y, event.button)
    end

    for _, event in event.view(event_type.mousemoved) do
        mouse.mousemoved(event.x, event.y)
    end

    for _, event in event.view(event_type.mousereleased) do
        mouse.mousereleased(event.x, event.y, event.button)
    end
end

return mouse