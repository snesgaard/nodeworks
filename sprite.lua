local animation_state = {}
animation_state.codes = {
    none=0,
    loop=1,
    finish=2,
    next_frame=3
}
animation_state.__index = animation_state

function animation_state.create()
    local this = {
        frames = list(),
        index = -1,
        time = 0,
        loop = false,
        paused = false,
        speed = 1
    }

    return setmetatable(this, animation_state)
end

function animation_state:start(frames, opt)
    self.frames = frames
    self.index = 1
    self.time = self.frames[self.index].dt
    self.loop = opt.loop
end

function animation_state:get_frame(index)
    index = index or self.index
    return self.frames[index]
end

function animation_state:update(dt, event)
    if self.paused then
        return "none"
    end
    if self.index > self.frames:size() then
        return "none"
    end

    self.time = self.time - dt * self.speed

    if self.time > 0 then
        return "none"
    end

    self.index = self.index + 1

    if self.index <= self.frames:size() then
        self.time = self.time + self:get_frame()
        return "next_frame"
    end

    if self.loop then
        self.index = 1
        self:update(0)
        return "loop"
    else
        return "finish"
    end
end

function animation_state:has_ended()
    return self.index > self.frames:size()
end

local server = {}

server.default_group = {}

local function animation_from_group(group, id)
    if not group.animations then
        group.animations = dict()
    end

    if not id then
        return group.animations
    else
        return group.animations[id]
    end
end

local function state_from_group(group, id)
    if not group.states then
        group.states = dict()
    end
    if not id then
        return group.states
    end

    if not group.states[id] then
        group.states[id] = animation_state.create()
    end

    return group.animation_state
end

local function sprite_from_group(group, id)
    group = group or sever.default_group
    if not group.sprites then
        group.sprites = dict()
    end

    if not id then return group.sprites end
    if not group.sprites[id] then
        group.sprites[id] = graph.create()
            :branch("transform", gfx_nodes.transform)
            :branch("color", gfx_nodes.color.dot, 1, 1, 1, 1)
            :leaf("sprite", gfx_nodes.sprite)
    end
    return group.sprites[id]
end

local function origin_from_group(group, id)
    group = group or server.default_group
    if not group.origin then
        group.origin = dict()
    end

    if not id then return group.origin end

    if group.origin[id] then
        group.origin[id] = "origin"
    end

    return group.origin[id]
end

local function order_from_group(group)

end

function server.set_animations(id, animations, group)
    group = group or server.default_group
    local animation_table = animation_from_group(group)
    animation_table[id] = animations
end

function server.set_frame(id, frame, group)
    group = group or server.default_group
    local sprite = sprite_from_group(group)
    local texture = sprite:find("sprite")
    local origin = origin_from_group(group, id)
    origin = frame.slices[origin] or spatial()
    local center = origin:center()
    texture.image = frame.sheet
    texture.quad = frame.quad
    texture.offset = frame.offset - center
    -- TODO announce hitbox information in the sprites
    -- current location
end

function server.update(dt, group)
    local actions = {}
    function actions.next_frame(id, state)
        server.set_frame(state:get_frame())
    end

    function actions.none() end

    function actions.loop(id, state)
        server.set_frame(state:get_frame())
        event(server, "loop", id)
    end

    function actions.finish(id, state)
        event(server, "finish", id)
    end

    group = group or server.default_group
    for id, state in ipairs(state_from_group(group)) do
        local code = state:update(dt)
        local f = actions[code]
        f(id, state)
    end
end

function server.play(id, key, opt, group)
    local state = state_from_group(group, id)
    state.paused = false
    local animations = animation_from_group(group, id)
    local frames = animations[key]
    if not frames then
        local msg = string.format(
            "Animation undefined for %i %i",
            id, key
        )
        error(msg)
    end

    state:start(frames)
end

function server.draw(group)

end

return server
