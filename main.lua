local nw = require "nodeworks"
--require("test")
print("ALL TEST PASSED")



function love.load()
    world = nw.ecs.world{nw.system.animation, nw.system.layer, nw.system.render}
    world:load_entities(function(world)
        layer = world:entity("background")
            :set(nw.component.layer_type, "fill")
            :set(nw.component.color, 1, 0, 0)

        layer = world:entity("layer")
            :set(nw.component.layer_pool)
            :set(nw.component.layer_type, "entitygroup")
            :set(nw.component.color, {1, 1, 1})
            :set(nw.component.priority, 1)

        box = world:entity("box")
            :set(nw.component.layer, layer)
            :set(nw.component.drawable, "rectangle")
            :set(nw.component.rectangle, spatial(0, 0, 100, 100))
            :set(nw.component.draw_mode, "fill")
            :set(nw.component.color, 0, 1, 0)
            :set(nw.component.hidden, true)

        sprite = world:entity("sprite")
            :set(nw.component.layer, layer)
            :set(nw.component.drawable, "image")
            :set(nw.component.color, {1, 1, 1})
            :set(nw.component.position, 100, 100)
            :set(nw.component.animation_state)
            :set(nw.component.body_slice, "body")
            :set(
                nw.component.animation_map,
                get_atlas("art/characters"),
                {
                    idle="gibbles_idle/animation",
                    run="gibbles_run"
                }
            )
    end)

    nw.system.animation.play(sprite, "idle")
end

function love.keypressed(key, scancode, isrepeat)
    if key == "r" then nw.system.animation.play(sprite, "run") end
    if key == "i" then nw.system.animation.play(sprite, "idle") end
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)
end

function love.draw()
    world("draw")
end
