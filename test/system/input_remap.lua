local nw = require "nodeworks"
local T = nw.third.knife.test

local left_right_observer = nw.ecs.system()

function left_right_observer.input_pressed(world, pool, input)
    local v = world:singleton()[input] or 0
    world:singleton()[input] = v + 1
end

function left_right_observer.input_released(world, pool, input)
    local v = world:singleton()[input] or 0
    world:singleton()[input] = v - 1
end

local scene = {}

T("input_remap", function(T)
    local world = nw.ecs.world{nw.system.input_remap, left_right_observer}
    local ctx = world:push(scene):find(scene)

    local keyboard_map = {a = "left", d = "right"}
    nw.system.input_remap.set_keyboard_map(ctx, keyboard_map)

    T("keyboard", function(T)
        for key, input in pairs(keyboard_map) do
            world("keypressed", key)
            T:assert(ctx:singleton()[input] == 1)
            world("keyreleased", key)
            T:assert(ctx:singleton()[input] == 0)
        end
    end)

    local gamepad_map = {x = "left", y = "right"}
    nw.system.input_remap.set_gamepad_button_remap(ctx, gamepad_map)

    T("gamepad", function(T)
        for button, input in pairs(gamepad_map) do
            world("gamepadpressed", "joystick", button)
            T:assert(ctx:singleton()[input] == 1)
            world("gamepadreleased", "joystick", button)
            T:assert(ctx:singleton()[input] == 0)
        end
    end)
end)
