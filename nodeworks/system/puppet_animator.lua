local clock = nw.system.time.clock
local collision = nw.system.collision

local puppet_animator = {}

local function slice_ids()
    return {}
end

local function magic_component(m) return m end

local function none_filter() return end

local function create_slice_hitboxes(id, key, slice, magic, properties)
    -- Slice collision detection
    local slice_ids = stack.ensure(slice_ids, id)
    slice_ids[key] = slice_ids[key] or nw.ecs.id.weak(key)
    local s_id = slice_ids[key]

    local p = stack.get(nw.component.position, id) or vec2()

    local predefined_c = {
        {nw.component.is_ghost},
        {magic_component, magic},
        {nw.component.name, key},
        {nw.component.owner, id}
    }

    stack.assemble(predefined_c, s_id)
    local prop = puppet_animator.slice_properties(properties, id)
    if prop then stack.assemble(prop, s_id) end

    collision.register(s_id, slice)
    collision.warp_to(s_id, p.x, p.y)
    collision.flip_to(s_id, stack.get(nw.component.mirror, id), none_filter)
    -- Move to check for collision
    local _, _, cols = collision.move(s_id, 0, 0)
end

local function clean_hitboxes(id, frame_slices, magic)
    local slice_ids = stack.ensure(slice_ids, id)
    for _, id in pairs(slice_ids) do
        local prev_magic = stack.get(magic_component, id)
        if prev_magic and prev_magic ~= magic then
            stack.destroy(id)
        else
            collision.unregister(id)
        end
    end
end

function puppet_animator.slice_properties(properties, owner_id)
end

function puppet_animator.spin_once(id, state, dt)
    local state_map = stack.get(nw.component.puppet_state_map, id) or dict()
    local state_time = state.time
    
    local video = state_map[state.name]
    if not video then return end
    local time = clock.get() - state_time
    
    local frame = video:frame(time)
    if not frame then return end
    
    -- Set frame
    stack.set(nw.component.frame, id, frame)
    
    clean_hitboxes(id, frame.slices, state.magic)
    for key, slice in pairs(frame.slices or {}) do
        create_slice_hitboxes(
            id, key, frame:get_slice(key, "body"), state.magic, frame.slice_data[key]
        )
    end
end

function puppet_animator.play(id, key)
    local state_map = stack.get(nw.component.state_map, id)
    if not state_map[key] then
        errorf("Tried to play animation, but it wasn't there: id = %s, key = %s", tostring(id), tostring(key))
    end
    stack.set(nw.component.puppet_state, id, key)
end

function puppet_animator.update(dt)
    for id, state in stack.view_table(nw.component.puppet_state) do
        puppet_animator.spin_once(id, state, dt)
        state.time = state.time
    end
end

function puppet_animator.spin()
    for _, dt in event.view("update") do puppet_animator.update(dt) end
end

function puppet_animator.is_done(id)
    local state = stack.get(nw.component.puppet_state, id)
    if not state then return true end
    local state_map = stack.get(nw.component.puppet_state_map, id)

    local video = state_map[state.name]
    if not video then return end
    local time = clock.get() - state.time
    return video:is_done(time)
end

function puppet_animator.ensure(id, key)
    local state = stack.get(nw.component.puppet_state, id)
    if state and state.name == key then return false end
    stack.set(nw.component.puppet_state, id, key)
    return true
end

return puppet_animator