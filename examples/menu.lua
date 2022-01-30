local nw = require "nodeworks"

function love.load()
    world = nw.ecs.world{
        nw.system.input_buffer,
        nw.system.render
    }

    menu_entity = world:entity()
        :set(nw.component.position, 100, 100)
    menu_items = {"foo", "bar", "baz"}

    menu_entity2 = world:entity()
        :set(nw.component.position, 200, 100)
    menu_items2 = {"dead", "beef", "yup"}

    local base_color = hsv.from_rgb(0.8, 0.4, 0.2)
    style = {}

    ui = nw.ui(world)

end

local function item_callback(core, item)
    if item == "foo" then
        ui:position("submenu", 200, 50)
        return core:menu("submenu", menu_items2)
    end
end

function love.update(dt)
    ui:position("main_menu", 150, 50)
    ui:menu("main_menu", menu_items, item_callback)
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
