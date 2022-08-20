local nw = require "nodeworks"

local function handle_keyframe_event(ctx, entity, next_frame, prev_frame)
    if not entity:get(nw.component.root_motion) then return end

    local body_prev = prev_frame.slices.body
    local body_next = next_frame.slices.body

    if not body_next and not body_prev then return end

    local base_motion = body_next:bottomcenter() - body_prev:bottomcenter()
    local scale = entity:get(nw.component.scale) or vec2(1, 1)
    local motion = base_motion * scale.x
    collision(ctx):move(entity. motion.x, motion.y)
end

return function(ctx)
    local keyframe_event = ctx:listen("animation:keyframe")

    while ctx:is_alive() do
        for _, event in ipairs(keyframe_event:pop()) do
            handle_keyframe_event(ctx, unpack(keyframe_event))
        end
        ctx:yield()
    end
end
