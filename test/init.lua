on_event_test = require "test.event_listener"

function isclose(a, b, tol)
    tol = tol or 1e-5
    return math.abs(a - b) < tol
end

require "test.system.collision"
require "test.system.collision_contact"
require "test.system.animation"
require "test.system.motion"
