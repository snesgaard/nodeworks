---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local stack = nw.ecs.stack

local function spin()
    while nw.system.event.swap() do
        nw.system.follow.spin()
    end
end

T("test_follow", function(T)
    stack.clear()

    local leader_id = "leader"
    local follow_id = "follower"
    local follow_follow_id = "at"

    stack.set(nw.component.is_following(leader_id), follow_id)
    stack.set(nw.component.is_following(follow_id), follow_follow_id)

    T("move", function (T)
        nw.system.collision.move_to(leader_id, 10, 0)

        local pos = stack.ensure(nw.component.position, follow_id)
        T:assert(pos ~= nil)
        T:assert(pos.x == 0)
        T:assert(pos.y == 0)

        spin()

        local pos = stack.get(nw.component.position, follow_id)
        T:assert(pos ~= nil)
        T:assert(pos.x == 10)
        T:assert(pos.y == 0)

        local pos = stack.get(nw.component.position, follow_follow_id)
        T:assert(pos ~= nil)
        T:assert(pos.x == 10)
        T:assert(pos.y == 0)
    end)

    T("flip", function(T)
        nw.system.collision.flip_to(leader_id, true)

        T:assert(not stack.get(nw.component.mirror, follow_id))

        spin()

        T:assert(stack.get(nw.component.mirror, follow_id))
        T:assert(stack.get(nw.component.mirror, follow_follow_id))
    end)
end)