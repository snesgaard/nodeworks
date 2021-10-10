local nw = require "nodeworks"

local system = nw.ecs.system(nw.component.particles)

function system.particles:update(dt)
    for _, entity in ipairs(self.pool) do
        entity[nw.component.particles]:update(dt)
    end
end

function system.particles:draw()
    for _, entity in ipairs(self.pool) do
        local draw_args = entity[nw.component.draw_args] or nw.component.draw_args()
        local transform = entity[nw.component.transform] or nw.component.transform()

        gfx.push()
        transform.push()
        gfx.draw(entity[nw.component.particles], draw_args:unpack())
        gfx.pop()
    end
end

return system
