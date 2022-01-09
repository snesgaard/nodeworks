local nw = require "."
--require("test")
print("ALL TEST PASSED")

function love.load()
    world = nw.ecs.world{nw.system.layer, nw.system.render}

    world:load_entities(function(world)
        layer = world:entity()
            :set(nw.component.layer_pool)
            :set(nw.component.layer_type, "objectgroup")
            :set(nw.component.priority, 1)

        box = world:entity()
            :set(nw.component.layer, layer)
    end)

    print(#world:get_pool(nw.system.layer))
    print(#world.entities)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
end

function love.draw()
end
