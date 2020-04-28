local Particles = {}

function Particles:create(...)
    self.particles = particles(...)
    self.transform = transform()
end

function Particles:update(dt)
    self.particles:update(dt)
end

function Particles:draw()
    gfx.draw(self.particles, 0, 0)
end

return Particles
