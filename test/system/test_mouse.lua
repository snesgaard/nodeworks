---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local mouse = nw.system.mouse
local stack = nw.stack
local camera = nw.system.camera
local collision = nw.system.collision
local event = nw.system.event

function mouse.get_screen_size()
    return 1280, 720
end

T("mouse", function(T)
    stack.clear()

    local camera_id = "camera"

    stack.set(nw.component.scale, camera_id, 1, 1)
    stack.set(nw.component.position, camera_id, 0, 0)
    stack.set(nw.component.is_camera, camera_id)

    T("camera_transforms", function(T)
        T("translation", function(T)
            local ox, oy = mouse.mouse_in_world(camera_id, 0, 0)
            local dx, dy = 100, 50
            nw.system.collision.warp_to(camera_id, dx, dy)
            local fx, fy = mouse.mouse_in_world(camera_id, 0, 0)
            T:assert(fx - ox == dx)
            T:assert(fy - oy == dy)
        end)
        T("scale", function(T)
            local ox, oy = mouse.mouse_in_world(camera_id, 0, 0)
            local s = 2
            stack.set(nw.component.scale, camera_id, s, s)
            local fx, fy = mouse.mouse_in_world(camera_id, 0, 0)
            T:assert(ox / fx == s)
            T:assert(oy / fy == s)
        end)
    end)
    
    local id = "foo"
    local hitbox = nw.spatial(0, 0, 0, 0):expand(100, 100)
    local w, h = mouse.get_screen_size()

    collision
        .register(id, hitbox)
        .warp_to(id, 0, 0)

    stack.set(nw.component.is_mouse_interactable, id)

    T("pressed", function()
        local button = 1
        mouse.mousepressed(w / 2, h / 2, button)
        event.swap()
        T:assert(#event.get(nw.event_type.entity_mousepressed) == 1)
        for _, event in event.view(nw.event_type.entity_mousepressed) do
            T:assert(event.id == id)
            T:assert(event.button == button)
        end
    end)

    T("released", function()
        local button = 1
        mouse.mousereleased(w / 2, h / 2, button)
        event.swap()
        T:assert(#event.get(nw.event_type.entity_mousereleased) == 1)
        for _, event in event.view(nw.event_type.entity_mousereleased) do
            T:assert(event.id == id)
            T:assert(event.button == button)
        end
    end)

    T("moved", function()
        mouse.mousemoved(w / 2, h / 2)
        T:assert(nw.dict.size(stack.get_table(nw.component.is_mouse_hovering)) == 1)
        for mid, _ in stack.view_table(nw.component.is_mouse_hovering) do
            T:assert(mid == id)
        end
    end)

end)