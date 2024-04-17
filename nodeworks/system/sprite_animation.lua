---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.ecs.id"
local ecs_id = require "nodeworks.ecs.id"
---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.system.event"
local event = require "nodeworks.system.event"
---@module "event_type"
local event_type = require "nodeworks.event_type"
---@module "time"
local time = require "nodeworks.system.time"
---@module "collision"
local collision = require "nodeworks.system.collision"
---@module "vec2"
local vec2 = require "nodeworks.core.vec2"

local private_component = {}

---@param t table<string, Id>
---@return table<string, Id>
function private_component.slice_hitbox_dict(t) return t or {} end

---@param f fun(properties: table<string, any>): table
---@return fun(properties: table<string, any>): table
function private_component.slice_assembly_from_properties(f) return f end

---@param a Id
---@param b Id
local function nil_filter(a, b) return end

local system_id = "__sprite_animation__"

local sprite_animation = {}

---@param id Id
---@param maybe_animation? table
function sprite_animation.update_single_entity(id, maybe_animation)
    local animation = maybe_animation or stack.get(component.animation, id)
    if animation == nil then return end
    local prev_frame = stack.get(component.frame, id)
    local frame = animation.video:frame(time.clock() - animation.init_time)

    -- If the frame is the same, simply return
    if prev_frame == frame then return end

    stack.set(component.frame, id, frame)

    -- Destroy prevous slices
    local prev_slices = stack.ensure(private_component.slice_hitbox_dict, id)
    for _, sid in pairs(prev_slices) do stack.destroy(sid) end

    stack.remove(private_component.slice_hitbox_dict, id)
    local slice_dict = stack.ensure(private_component.slice_hitbox_dict, id)

    local pos = stack.get(component.position, id) or vec2(0, 0)
    local mirror = stack.get(component.mirror, id)
    -- Create new slices
    for name, rect in pairs(frame.slices) do
        -- Generate ID
        local sid = ecs_id.weak(
            string.format("%s/slice/%s", tostring(id), name)
        )
        -- Setup hitbox in world space
        collision.register(sid, rect)
        collision.warp_to(sid, pos.x, pos.y)
        collision.flip_to(sid, mirror, nil_filter)
        -- Follow the parent
        stack.set(component.is_following(id), sid)
        -- Store id
        slice_dict[name] = sid

        -- Populate additional properties if needed
        local assembly = sprite_animation.slice_assembly_from_properties(
            frame.slice_data[name] or {}
        )
        if assembly then stack.assemble(assembly, sid) end

    end
end


---@param properties table<string, any>
---@return table|nil
function sprite_animation.slice_assembly_from_properties(properties)
    local maybe_assembly_func = stack.get(private_component.slice_assembly_from_properties, system_id)
    if maybe_assembly_func == nil then return end
    return maybe_assembly_func(properties)
end


---@param assembly_func fun(properties: table<string, any>): table
function sprite_animation.set_slice_assembly(assembly_func)
    stack.set(private_component.slice_assembly_from_properties, system_id, assembly_func)
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