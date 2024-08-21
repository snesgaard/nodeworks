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

local function nil_filter() end

local function cross_filter() return "cross" end

local system_id = "__sprite_animation__"

local function get_slice_id(slice_dict, id, name)
    local i = slice_dict[name]
    if i then return i end

    local sid = ecs_id.weak(string.format("%s/slice/%s", tostring(id), tostring(name)))
    slice_dict[name] = sid
    return sid
end

local sprite_animation = {}

---@param owner_id Id
---@return table
function sprite_animation.get_slice_dict(owner_id)
    return stack.ensure(private_component.slice_hitbox_dict, owner_id)
end

function sprite_animation.update_slice_entities(owner_id, slices, slice_data)
    local slice_dict = stack.ensure(private_component.slice_hitbox_dict, owner_id)

    -- Despawn, if not in current slice list
    for name, id in pairs(slice_dict) do
        if not slices[name] then stack.destroy(id) end
    end

    local pos = stack.get(component.position, owner_id) or vec2(0, 0)
    local mirror = stack.get(component.mirror, owner_id)
    -- Update or spawn otherwise
    for name, slice in pairs(slices) do
        local id = get_slice_id(slice_dict, owner_id, name)
        -- Update presence in collision system if needed
        collision.unregister(id)
        -- Register and move hitbox to proper position
        collision.register(id, slice)
        collision.warp_to(id, pos.x, pos.y)
        collision.flip_to(id, mirror, nil_filter)
        -- Set hitbox as being following
        stack.set(component.is_following(owner_id), id)
        -- Setup properties
        local assembly = sprite_animation.slice_assembly_from_properties(slice_data[name] or {})
        if assembly then stack.assemble(assembly, id) end
        -- Trigger collisions if needed
        collision.move(id, 0, 0, cross_filter)
    end
end

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

    -- Transform slices to body frame
    local slices = {}
    for name, _ in pairs(frame.slices) do
        slices[name] = frame:get_slice(name, "body")
    end

    -- Update slices
    sprite_animation.update_slice_entities(id, slices, frame.slice_data)
end


---@param properties table<string, any>
---@return table|nil
function sprite_animation.slice_assembly_from_properties(properties)
    local maybe_assembly_func = stack.get(private_component.slice_assembly_from_properties, system_id)
    if maybe_assembly_func == nil then return end
    return maybe_assembly_func(properties)
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