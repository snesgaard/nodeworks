local systems = {}

systems.animation = require(... .. ".animation")

systems.particles = ecs.system(components.particles)

function systems.particles:update(dt)
    for _, entity in ipairs(self.pool) do
        entity[components.particles]:update(dt)
    end
end

function systems.particles:draw()
    for _, entity in ipairs(self.pool) do
        local draw_args = entity[components.draw_args] or components.draw_args()
        local transform = entity[components.transform] or components.transform()

        gfx.push()
        transform.push()
        gfx.draw(entity[components.particles], draw_args:unpack())
        gfx.pop()
    end
end

return systems
