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
        speed = 1
    }

    return setmetatable(this, animation_state)
end

function animation_state:start(frames, opt)
    self.frames = frames
    self.index = 1
    self.time = self.frames[self.index].dt
end

function animation_state:get_frame(index)
    index = index or self.index
    return self.frames[index]
end

function animation_state:update(dt, event)
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

    return "finish"
end

function animation_state:loop()
    self.index = 0
    self:update(0)
    return self
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
        local a = atlas:get_animation(val)
        if not a then
            local msg = string.format("not found %s", key)
            error(msg)
        end
        self.animation_alias[key] = a
    end
    self.stack = list()
    self.state = animation_state.create()
    self.graph = graph.create()
        :branch("color", gfx_nodes.color.dot, 1, 1, 1, 1)
        :branch("texture", gfx_nodes.sprite)
end

function Sprite:color()
    return self.graph:find("color")
end

function Sprite:play(key, opt)
    if not self.atlas then
        error("Atlas not set")
    end
    local anime = self.animation_alias[key]
    if not anime then
        error(string.format("animation undefined %s", key))
    end
    self.state:start(anime, key)
end

local function format_key(key)
    if type(key) == "table" then
        return dict(key)
    else
        return dict(key)
    end
end

function Sprite:queue(...)
    local keys = list(...)
    local frames = keys
        :map(function(key)
            -- Create a level-1 copy to make share state can be set outside
            local opt = dict(format_key(key))
            -- O
            opt.frames = self.animation_alias[unpack(opt)]
            if not opt.frames then
                error(string.format("undefined %s", opt[1]))
            end
            return opt
        end)

    local f = frames:tail()
    f.loop = f.loop == nil and true or f.loop

    self.queue = frames:body()
    self.opt = frames:head()
    self.state:start(self.opt.frames)
    self.graph:reset("texture", self.state:get_frame())
end

local action = {}

function action.next_frame(self, opt, state)
    self.graph:reset("texture", state:get_frame())
end

function action.finish(self, opt, state)
    if self.opt.loop then
        event(self, "loop", unpack(opt))
        self.graph:reset("texture", state:loop():get_frame())
        return
    end

    event(self, "finish", unpack(opt))
    if self.queue:size() <= 0 then
        return self.queue:head(), self.queue:body()
    end
end

function Sprite:__update(dt)
    if not self.opt then return end
    if self.opt.paused then return end

    local speed = self.opt.speed or 1

    local code = self.state:update(dt * speed)
    local a = action[code] or function() end
    local next_opt, next_queue = a(self, self.opt, self.state)
    if next_opt then
        self.opt = next_opt
        self.state:start(next_opt.frames)
    end
    if next_queue then
        self.queue = next_queue
    end
end

function Sprite:__draw()
    self.graph:traverse()
end

return Sprite
