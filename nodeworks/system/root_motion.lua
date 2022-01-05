local nw = require "nodeworks"

local root_motion_system = nw.ecs.system(
    nw.component.root_motion, nw.component.position
)

function root_motion_system.on_next_frame(world, pool, entity, prev_frame, next_frame)
    if not pool[entity] then return end

    local next_body = next_frame.slices.body
    local prev_body = prev_frame.slices.body

    if not next_body or not prev_body then return end


    local motion = next_frame.slices.body:center() - prev_frame.slices.body:center()
    if math.abs(motion.x) < 1e-6 and math.abs(motion.y) < 1e-6  then return end

    local mirror = entity[nw.component.mirror]
    if mirror then motion.x = -motion.x end
    --print(motion)
    nw.system.collision.move(entity, motion.x, motion.y)
end

return root_motion_system
