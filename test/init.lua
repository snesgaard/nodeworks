nw = require "nodeworks"
T = nw.third.knife.test

function isclose(a, b, tol)
    tol = tol or 1e-5
    return math.abs(a - b) < tol
end

function list_equal(a, b, cmp)
    if #a ~= #b then return false end

    cmp = cmp or function(x, y) return x == y end

    for i = 1, #a do
        if not cmp(a[i], b[i]) then return false end
    end

    return true
end

function table_equal(a, b)
    for key, a_value in pairs(a) do
        if b[key] ~= a_value then return false end
    end

    return true
end



require "test.core.stack"
require "test.core.pool"
require "test.core.event_queue"
require "test.core.result"
require "test.core.test_task"
require "test.core.tree"
require "test.core.test_animation"
require "test.core.test_computation"
require "test.core.test_video"
require "test.core.transform"

require "test.ecs.id"
require "test.ecs.world"
require "test.ecs.stack"

require "test.system.event"
require "test.system.timer"
require "test.system.collision"
require "test.system.input"
require "test.system.sprite_state"