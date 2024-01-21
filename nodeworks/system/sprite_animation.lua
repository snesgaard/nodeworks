local nw = require "nodeworks"

local function set_sprite_state(id, name, do_loop)
    local prev_state = stack.get(nw.component.sprite_state, id)
    if prev_state and prev_state.name == name then return end
    local time = nw.system.time.clock.get()
    stack.set(nw.component.sprite_state, id, name, time, do_loop)
end

local function get_sprite_state_video_and_time(id)
    local sprite_state = stack.get(nw.component.sprite_state, id)
    if not sprite_state then return end
    
    local sprite_state_map = stack.get(nw.component.sprite_state_map, id)
    if not sprite_state_map then return end
    
    local video = sprite_state_map[sprite_state.name or "unknown"]
    if not video then return end

    local time = nw.system.time.clock.get() - (sprite_state.time or 0)
    return sprite_state, video, time
end

local sprite_animation = {}

function sprite_animation.get_frame(id)
    local sprite_state, video, time = get_sprite_state_video_and_time(id)
    if not sprite_state then return end

    return video:frame(time)
end

function sprite_animation.get_slices_and_data(id)
    local frame = sprite_animation.get_frame(id)
    if not frame then return end
    return frame.slices, frame.slice_data
end 

function sprite_animation.is_done(id)
    local sprite_state, video, time = get_sprite_state_video_and_time(id)
    if not sprite_state then return true end
    
    return video:is_done(time)
end

function sprite_animation.play(id, name)
    local do_loop = true
    set_sprite_state(id, name, do_loop)
    return sprite_animation
end

function sprite_animation.clear(id)
    stack.remove(nw.component.sprite_state, id)
    return sprite_animation
end

return sprite_animation