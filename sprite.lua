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

function animation_state:pause()
    self.paused = true
end

function animation_state:play()
    self.paused = false
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
        self.time = self.time + self:get_frame().dt
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

local Sprite = {}
Sprite.__index = Sprite

function Sprite:create(animation_alias, atlas)
    atlas = get_atlas(atlas)
    self.animation_alias = dict()
    for key, val in pairs(animation_alias) do
        local a = atlas:get_animation(key)
        if not a then
            local msg = string.format("not found %s", key)
            error(msg)
        end
        self.animation_alias[key] = a
    end
    self.stack = list()
    self.state = nil
    self.graph = graph.create()
        :branch("color", gfx_nodes.color.set, 1, 1, 1, 1)
        :branch("texture", gfx_nodes.sprite)
end

function Sprite:play(key, opt)
    if not self.atlas then
        error("Atlas not set")
    end
    local anime = self.animation_alias[key]
    if not key then
        error(string.format("animation undefined %s", key))
    end
    self.state:start(anime, key)
end

local action = {}

function action.next_frame(self, state)
    local frame = state:get_frame()
    self.graph:reset("texture", frame)
end

function action.loop(self, state)
    event(self, "loop")
    local frame = state:get_frame()
    self.graph:reset("texture", frame)
end

function action.finish(self, state)
    event(self, "finish")
    state:pause()
end

function Sprite:__update(dt)
    if not self.state then return end

    local code = self.state:update(dt)
    local a = action[code]
    if a then a(self, self.state) end
end

function Sprite:__draw()
    self.graph:traverse()
end

return server
