on_event_test = require "test.event_listener"

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

require "test.ecs.event"
require "test.system.collision"
require "test.system.collision_contact"
require "test.system.animation"
require "test.system.motion"
require "test.system.parenting"
require "test.system.root_motion"
