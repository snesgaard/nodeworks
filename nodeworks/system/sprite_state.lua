local nw = require "nodeworks"
local event = nw.system.event

local component = {}

function component.sprite_state(state, time)
    return {
        state = state or "__nothing__",
        time = time or 0
    }
end

local system_sprite_state = {}

function system_sprite_state.update_once(id, sprite_state, dt)
    sprite_state.time = sprite_state.time + dt

    local sprite_state_map = stack.ensure(nw.component.sprite_state_map, id)
    local video = sprite_state_map[sprite_state.state]
    if not video then return end

    local frame = video:frame(sprite_state.time)
    if not frame then return end

    local prev_frame = stack.get(nw.component.frame, id)
    stack.set(nw.component.frame, id, frame)

    if prev_frame ~= frame then
        event.emit("frame_change", frame, prev_frame)
    end
end

function system_sprite_state.update(dt)
    for id, sprite_state in stack.view_table(component.sprite_state) do
        system_sprite_state.update_once(id, sprite_state, dt)
    end
end

function system_sprite_state.spin()
    for _, dt in event.view("update") do system_sprite_state.update(dt) end
end

function system_sprite_state.set(id, state)
    local sprite_state = stack.ensure(component.sprite_state, id)
    if sprite_state.state == state then return false end
    stack.set(component.sprite_state, id)
    return true
end

function system_sprite_state.is_done(id)
    local sprite_state = stack.ensure(component.sprite_state, id)
    if not sprite_state then return true end

    local sprite_state_map = stack.ensure(nw.component.sprite_state_map, id)
    local video = sprite_state_map[sprite_state.state]
    if not video then return true end

    return video:is_done(sprite_state.time)
end

return system_sprite_state