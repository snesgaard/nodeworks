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

function table_equal(a, b)
    for key, a_value in pairs(a) do
        if b[key] ~= a_value then return false end
    end

    return true
end



require "test.core.stack"
require "test.core.pool"
require "test.core.event_queue"

require "test.ecs.promise"
require "test.ecs.reducer"
require "test.system.collision"
require "test.system.tween"
require "test.system.animation"
require "test.system.camera"
require "test.system.motion"
--[[
require "test.ecs.pool"
require "test.ecs.entity"
require "test.ecs.system"
require "test.ecs.world"

require "test.system.root_motion"
require "test.system.collision_contact"
require "test.system.parenting"
require "test.system.input_buffer"
require "test.system.input_remap"
require "test.system.ai"
]]--
