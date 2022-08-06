local nw = require "nodeworks"

local Tweens = class()

return function(ctx)
    while ctx.alive do
        ctx:visit_event("update", update_tweens)

        coroutine.yield()
    end
end
