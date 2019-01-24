math = require "math"

json = require(... .. ".third.json")

require(... .. ".functional")
List = require(... .. ".list")
Dictionary = require(... ..  ".dictionary")
Event = require(... .. ".event")
Spatial = require(... .. ".spatial")

echo = require(... .. ".echo")

id_gen = require(... .. ".id_gen")

list = List.create
dict = Dictionary.create
event = Event.create
spatial = Spatial.create

Atlas = require(... .. ".atlas")
vec2 = require(... .. ".vec2")
Node = require(... .. ".node")
NodeUI = require(... .. ".nodeui")
Sprite = require(... .. ".sprite")
Structure = require(... .. ".structure")
Frame = require(... .. ".frame")
DrawStack = require(... .. ".drawstack")

moon = require (... .. ".third.moonshine")
local knife_path = ... .. ".third.knife.knife"
timer = require (knife_path .. ".timer")
sti = require(... .. ".third.Simple-Tiled-Implementation.sti")
ease = require(... .. ".third.easing")
require(... .. ".ease")
log = require(... .. ".third.log")

lume = require(... .. ".third.lume")
lurker = require(... .. ".third.lurker")

suit = require (... .. ".third.SUIT")
require (... .. '.ui')
require (... .. ".third.patch")

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
    local q = atlas:get_animation(name):head()
    return q, atlas
end

local font_cache = {}

function font(size)
    if not font_cache[size] then
        font_cache[size] = gfx.newFont(size)
    end
    return font_cache[size]
end

gfx.setDefaultFilter("nearest", "nearest")
