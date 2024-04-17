---@module "nodeworks.system.event"
local event = require "nodeworks.system.event"
---@module "event_type"
local event_type = require "nodeworks.event_type"
---@module "stack"
local stack = require "nodeworks.ecs.stack"
---@module "component"
local component = require "nodeworks.component"
---@module "collision"
local collision = require "nodeworks.system.collision"

local follow = {}

---@param id Id
---@param x number
---@param y number
function follow.spin_move(id, x, y)
    for fid, _ in stack.view_table(component.is_following(id)) do
        collision.move_to(fid, x, y)
    end
end

---@param id Id
---@param mirror boolean|nil
function follow.spin_flip(id, mirror)
    for fid, _ in stack.view_table(component.is_following(id)) do
        collision.flip_to(fid, mirror)
    end
end

function follow.spin()
    for _, move_event in event.view(event_type.move) do
        follow.spin_move(move_event.id, move_event.ax, move_event.ay)
    end

    for _, flip_event in event.view(event_type.flip_to) do
        follow.spin_flip(flip_event.id, flip_event.mirror)
    end
end

return follow