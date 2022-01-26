local nw = require "nodeworks"

function love.load()
    world = nw.ecs.world{
        nw.system.input_buffer,
        nw.system.render,
        nw.system.delegate
    }

    menu_entity = world:entity()
        :set(nw.component.position, 100, 100)
    menu_items = {"foo", "bar", "baz"}

    menu_entity2 = world:entity()
        :set(nw.component.position, 100, 100)
    menu_items2 = {"dead", "beef", "yup"}

    local base_color = hsv.from_rgb(0.8, 0.4, 0.2)
    style = {}

end

function love.update(dt)
    if nw.ui.menu(menu_entity, menu_items, style) then
        nw.ui.menu(menu_entity2, menu_items2, style)
    end

    world("update", dt)
end

function love.draw()
    world("draw")
end

function love.keypressed(key, scancode, isrepeat)
    world("input_pressed", key)
    if key == "escape" then love.event.quit() end
end

function love.keyreleased(key)
    world("input_released", key)
end
