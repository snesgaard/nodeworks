---@module "event_type"
local event_type = require "nodeworks.event_type"
---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.system.event"
local event = require "nodeworks.system.event"
---@module "nodeworks.core.misc"
local misc = require "nodeworks.core.misc"
---@module "nodeworks.core.vec2"
local vec2 = require "nodeworks.core.vec2"


local particles = {}

function particles.update(dt)
    for _, p in stack.view_table(component.particles) do p:update(dt) end

    for id, p in stack.view_table(component.particles) do
        if stack.get(component.die_on_particle_empty, id) and p:getCount() == 0 then
            stack.destroy(id)
        end
    end
end

function particles.spin()
    for _, dt in event.view(event_type.update) do particles.update(dt) end
end


return particles