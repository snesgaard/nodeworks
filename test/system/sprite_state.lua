local sprite_state = nw.system.sprite_state

local state_map = {
    idle = Video.create(list({dt = 1}, {dt = 2}, {dt = 3})),
    attack = Video.create{{dt = 1}, {dt = 2}}
}

T("sprite_state", function(T)
    local id = {}
    
    stack.set(sprite_state.map, id, state_map)
    T:assert(stack.get(sprite_state.map, id) == state_map)

    sprite_state.play(id, "idle")
end)