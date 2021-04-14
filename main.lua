require "init"
components = require "components"
local ecs = require "ecs"

local systems = {}

local gravity_system = ecs.system{components.position, components.velocity}

function gravity_system:update(dt)
    for _, entity in ipairs(self.pool) do
        local p = entity[components.position]
        local v = entity[components.velocity]
        entity[components.position] = p + v * dt
    end
end

function gravity_system:draw()
    for _, entity in ipairs(self.pool) do
        local p = entity[components.position]
        gfx.circle("fill", p.x, p.y, 3)
    end
end


function love.load()
    world = ecs.world(gravity_system)

    poison = components.poison{
        [components.tick] = {10},
        [components.timer] = {0.2},
        [components.multiplier] = {0.05},
    }

    test_entity = ecs.entity(world)
        :add(components.position, 100, 200)
        :add(components.velocity, 20)
end

function love.keypressed(key, scancode, isrepeat)
    event("keypressed", key)

    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)
    event:spin()
end

function love.draw()
    world("draw")
end
