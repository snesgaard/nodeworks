---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.system.event"
local event = require "nodeworks.system.event"
---@module "event_type"
local event_type = require "nodeworks.event_type"
---@module "time"
local time = require "nodeworks.system.time"

local sprite_animation = {}

---@param id Id
---@param maybe_animation? table
function sprite_animation.update_single_entity(id, maybe_animation)
    local animation = maybe_animation or stack.get(component.animation, id)
    if animation == nil then return end
    local frame = animation.video:frame(time.clock() - animation.init_time)
    stack.set(component.frame, id, frame)
end

function sprite_animation.update()
    for id, animation in stack.view_table(component.animation) do
        sprite_animation.update_single_entity(id, animation)        
    end
end

function sprite_animation.spin()
    for _, _ in event.view(event_type.update) do sprite_animation.update() end
end

---@param id Id
---@param name string
---@return boolean
function sprite_animation.play(id, name)
    local map = stack.get(component.animation_map, id) or {}
    local animation = map[name]
    if animation == nil then return false end

    stack.set(component.animation, id, animation, time.clock(), name)
    sprite_animation.update_single_entity(id)
    return true
end

function sprite_animation.stop(id)
    stack.remove(component.animation, id)
end

---@param id Id
---@param name string
---@return boolean
function sprite_animation.ensure(id, name)
    local animation = stack.get(component.animation, id)
    if animation ~= nil and animation.name == name then return false end
    return sprite_animation.play(id, name)
end

---@param id Id
---@return boolean
function sprite_animation.is_done(id)
    local animation = stack.get(component.animation, id)
    if animation == nil then return true end
    local video = animation.video
    return video:is_done(time.clock() - animation.init_time)
end

return sprite_animation