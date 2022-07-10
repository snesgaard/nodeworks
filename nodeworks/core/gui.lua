local gui = {}
gui.__index = gui

function gui.create(base, ...)
    local this = setmetatable(
         {
             base=base,
             tweens={},
             animations={}
         },
         gui
    )

    return this:init(...)
end

function gui:init(...)
    self.state = self.base.init(...)
    return self
end

local function handle_action_return(self, state, ...)
    self.state = state or self.state
    return ...
end

function gui:action(key, ...)
    local f = self.base[key]
    if not f then return end
    return handle_action_return(self, f(self, self.state, ...))
end

function gui:draw(...)
    local f = self.base.draw
    local s = self.state
    if not s or not f then return end
    f(self, s)
end

function gui:update(dt)
    for _, tween in pairs(self.tweens) do tween:update(dt) end

    for _, anime in pairs(self.animations) do anime:update(dt) end

    return self:action("update", dt)
end

function gui:tween(key)
    local t = self.tweens[key]
    if not t then
        local t = imtween.create()
        self.tweens[key] = t
        return t
    else
        return t
    end
end

function gui:animation(id)
    local id = id or "default"
    local a = self.animations[id]
    if not a then
        local a = im_animation.create()
        self.animations[id] = a
        return a
    else
        return a
    end
end

function gui:__call(...) return self:action(...) end

return gui.create
