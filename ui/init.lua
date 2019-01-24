-- patch SUIT
local old_new = suit.new

-- Overwrite new function to inclue new types
BASE = ...
local function new_new(theme)
    local s = old_new(theme)
    s.Frame = require(BASE ..".frame")
    s.Progress = require(BASE ..".progress")
    s.Image = require(BASE .. ".image")
    s.Generic = require(BASE .. ".generic")
    s.new = new_new
    return s
end
suit.new = new_new

local new_themes = require(BASE .. ".theme")
local default_themes = suit._instance.theme

for key, val in pairs(new_themes) do
    default_themes[key] = val
end

for key, val in pairs(default_themes) do
    new_themes[key] = val
end

suit = suit.new()
