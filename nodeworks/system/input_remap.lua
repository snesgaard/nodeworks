local nw = require "nodeworks"

local component = {}

function component.keyboard_map(map) return map or {} end
function component.gamepad_button_map(map) return map or {} end
function component.gamepad_axis_threshold(threshold) return threshold or 0.3 end
function component.gamepad_axis_map(map) return map or {} end

local input_remap = nw.ecs.system()

function input_remap.set_keyboard_map(world, map)
    world:singleton():set(component.keyboard_map, map)
end

function input_remap.set_gamepad_button_remap(world, map)
    world:singleton():set(component.gamepad_button_map, map)
end

function input_remap.keypressed(world, pool, key)
    local map = world:singleton():ensure(component.keyboard_map)
    local input = map[key]
    if not input then return end
    world("input_pressed", input)
end

function input_remap.keyreleased(world, pool, key)
    local map = world:singleton():ensure(component.keyboard_map)
    local input = map[key]
    if not input then return end
    world("input_released", input)
end

function input_remap.gamepadpressed(world, pool, joystick, key)
    local map = world:singleton():ensure(component.gamepad_button_map)
    local input = map[key]
    if not input then return end
    world("input_pressed", input)
end

function input_remap.gamepadreleased(world, pool, joystick, key)
    local map = world:singleton():ensure(component.gamepad_button_map)
    local input = map[key]
    if not input then return end
    world("input_released", input)
end

function input_remap.gamepadaxis(world, joystick, axis, value)
    local map = world:singleton():ensure(component.gamepad_button_map)
    local input = map[key]
    if not input then return end
    world("input_axis", input, value)
end

function input_remap.is_down(entity, input)
    local keyboard_map = entity % component.keyboard_map or {}
    local gamepad_map = entity % component.gamepad_map or {}

    for key, key_input in pairs(keyboard_map) do
        if key_input == input and love.keyboard.isDown(key) then
            return true
        end
    end

    for button, button_input in pairs(gamepad_map) do
        if button_input == input then
            for _, joystick in ipairs(love.joystick.getJoysticks()) do
                if joystick.isGamepadDown(button) then
                    return true
                end
            end
        end
    end

    return false
end

return input_remap
