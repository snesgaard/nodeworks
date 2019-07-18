function attribute(key)
    return function(self, val)
        if val then
            self[key] = val
            return self
        else
            return self[key]
        end
    end
end

function unpacked(f)
    return function(table) f(unpack(table)) end
end

BASE = ...

BASE = BASE == "init" and "" or BASE

math = require "math"

json = require(BASE .. ".third.json")

require(BASE .. ".functional")
List = require(BASE .. ".list")
Dictionary = require(BASE ..  ".dictionary")
Event = require(BASE .. ".event")
EventServer = require(BASE .. ".event_server")
AnimationPlayer = require(BASE .. ".animation_player")
Spatial = require(BASE .. ".spatial")

echo = require(BASE .. ".echo")

id_gen = require(BASE .. ".id_gen")

list = List.create
dict = Dictionary.create
--event = Event.create
spatial = Spatial.create
event_server = EventServer
animation_player = AnimationPlayer
state = require(BASE .. ".state")
color = require(BASE .. ".color")

event = event_server()

Atlas = require(BASE .. ".atlas")
vec2 = require(BASE .. ".vec2")
Node = require(BASE .. ".node")
Sprite = require(BASE .. ".sprite")
Structure = require(BASE .. ".structure")
Frame = require(BASE .. ".frame")
DrawStack = require(BASE .. ".drawstack")
Stack = require(BASE .. ".stack")
particles = require(BASE .. ".particles")

moon = require (BASE .. ".third.moonshine")
local knife_path = BASE .. ".third.knife.knife"
--timer = require (knife_path .. ".timer")
sti = require(BASE .. ".third.Simple-Tiled-Implementation.sti")
ease = require(BASE .. ".third.easing")
require(BASE .. ".ease")
log = require(BASE .. ".third.log")
tween = require(BASE .. ".tween")

lume = require(BASE .. ".third.lume")
lurker = require(BASE .. ".third.lurker")

suit = require (BASE .. ".third.SUIT")
require (BASE .. ".third.patch")

gfx = love.graphics
rng = love.math.random

function gfx.prerender(w, h, f, ...)
    local args = {...}
    local prev_c = gfx.getCanvas()
    local c = gfx.newCanvas(w, h)
    gfx.setCanvas({c, stencil=true})
    f(w, h, unpack(args))
    gfx.setCanvas(prev_c)
    return c
end

function gfx.hex2color(hex)
    local splitToRGB = {}

    if # hex < 6 then hex = hex .. string.rep("F", 6 - # hex) end --flesh out bad hexes

    for x = 1, # hex - 1, 2 do
    	 table.insert(splitToRGB, tonumber(hex:sub(x, x + 1), 16) / 255.0) --convert hexes to dec
    	 if splitToRGB[# splitToRGB] < 0 then slpitToRGB[# splitToRGB] = 0 end --prevents negative values
    end
    return list(unpack(splitToRGB))
end

function reload(p)
    package.loaded[p] = nil
    return require(p)
end

function gfx.read_shader(...)
    local paths = list(...)
        :filter(function(p)
            local info = love.filesystem.getInfo(p)
            if not info then
                log.warn("Shader <%s> does not exist", p)
            end
            return info
        end)
        :map(function(p)
            return love.filesystem.read(p)
        end)

    return gfx.newShader(unpack(paths))
end

function math.cycle(value, min, max)
    if min >= max then
        return value
    end
    if value < min then
        return math.cycle(value + max - min + 1, min, max)
    elseif value > max then
        return math.cycle(value - max + min - 1, min, max)
    else
        return value
    end
end

function math.remap(value, prev_min, prev_max, next_min, next_max)
    local x = (value  - prev_min) / (prev_max - prev_min)

    return x * (next_max - next_min) + next_min
end

function math.clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

function istype(Type, object)
    if type(Type) == type(object) and type(Type) ~= "table" then
        return true
    elseif type(Type) == "table" and type(object) == "table" then
        return Type.__index == object.__index
    else
        return false
    end
end

function string.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t=List.create() ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function string.pathsplit(path)
    return string.split(
        path:gsub("/../", "/__parent/"):gsub("../", "__parent/"), '/'
    )
end

atlas_cache = {}
function get_atlas(path)
    if not atlas_cache[path] then
        atlas_cache[path] = Atlas.create(path)
    end
    return atlas_cache[path]
end

function clear_atlas(path)
    atlas_cache[path] = nil
end

function get_icon(name, atlas)
    atlas = get_atlas(atlas or "art/icons")
    local q = atlas:get_animation(name)
    if q.head then
        return q:head(), atlas
    else
        return q, atlas
    end
end

function frame_offset(frame)
    return (spatial(frame.quad:getViewport()):size() * 0.5):tolist()
end

local font_cache = {}

function font(size)
    if not font_cache[size] then
        font_cache[size] = gfx.newFont(size)
    end
    return font_cache[size]
end

function identity(...) return ... end

function compose(...)
    local funcs = {...}
    local prev = identity
    local next
    for i = #funcs, 1, -1 do
        local f = funcs[i]
        prev = function(...)
            return prev(f(...))
        end
    end
    return prev
end


gfx.setDefaultFilter("nearest", "nearest")
