local nw = require "nodeworks"

local function update_tweens(ctx, dt)
    for _, entity in ipairs(ctx:pool(nw.component.tween)) do
        local tween = entity % nw.component.tween
        tween:update(dt)
        if tween:is_done() and entity:get(nw.component.release_on_complete) then
            entity:destroy()
        end
    end
end

return function(ctx)
    while ctx.alive do
        ctx:visit_event("update", update_tweens)

        coroutine.yield()
    end
end
