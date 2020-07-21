require "init"
components = require "components"

local systems = {}

systems.default = list(weapon, affinity) + systems.__ailments() + list(shield, charge) + damage



function love.load()
    world = ecs.world.create()

    poison = components.poison{
        [components.tick] = {10},
        [components.timer] = {0.2},
        [components.multiplier] = {0.05},
    }


end

function love.keypressed(key, scancode, isrepeat)
    event("keypressed", key)
end

function love.update(dt)
    event:spin()
end
