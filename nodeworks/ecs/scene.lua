local nw = require "nodeworks"

local manager = {}
manager.__index = manager

local function get_on_pushed(scene)
    if type(scene) == "table" then
        return scene.on_pushed
    elseif type(scene) == "function" then
        return scene
    end
end

local function get_on_poped(scene)
    if type(scene) == "table" then
        return scene.on_poped
    end
end

local function filter_event(scene, event, ...)
    if type(scene) == "table" and scene.filter then
        return scene.filter(event, ...)
    end

    return false
end

local implementation = {}

function implementation:push(scene, ...)
    self.scenes:push(scene)
    self.worlds:push(nw.ecs.world():set_cosmos(self))
    local f = get_on_pushed(scene)
    if f then f(self.worlds:peek(), ...) end
end

function implementation:pop()
    local prev_scene = self.scenes:pop()
    local prev_world = self.worlds:pop()
    local f = get_on_poped(prev_scene)
    if f then f(prev_scene) end
end

function implementation:move(...)
    self:pop()
    self:push(...)
end

function implementation:event(...)
    local s = self.scenes:size()
    for i = s, 1, -1 do
        local scene = self.scenes[i]
        local world = self.worlds[i]
        world(...)
        if not filter_event(scene, ...) then return end
    end
end

function implementation:__call(...) return self:event(...) end

for key, func in pairs(implementation) do
    manager[key] = function(...)
        self.event_queue(func, self, ...)
    end
end

return function()
    return setmetatable(
        {
            scenes = stack(),
            worlds = stack(),
            event_queue = event_queue()
        },
        manager
    )
end
