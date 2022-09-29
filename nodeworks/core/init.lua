local BASE = ...
BASE = BASE == "init" and "" or BASE

gfx = love.graphics

require(BASE .. ".functional")
Atlas = require(BASE .. ".atlas")
Color = require(BASE .. ".color")
HSV = require(BASE .. ".hsv")
Dictionary = require(BASE ..  ".dictionary")
Frame = require(BASE .. ".frame")
require(BASE .. ".functional")
List = require(BASE .. ".list")
Pool = require(BASE .. ".pool")
Stack = require(BASE .. ".stack")
Mat3 = require(BASE .. ".mat3")
Spatial = require(BASE .. ".spatial")
Transform = require(BASE .. ".transform")
EventQueue = require(BASE .. ".event_queue")
vec2 = require(BASE .. ".vec2")
particles = require(BASE .. ".particles")
ease = require(BASE .. ".ease")
bump_debug = require(BASE .. ".bump_debug")
layer = require(BASE .. ".layer")
imtween = require(BASE .. ".imtween")
im_animation = require(BASE .. ".imanimation")
gui = require(BASE .. ".gui")

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

event_queue = EventQueue.create
color = Color.create
stack = Stack.create
pool = Pool.create
dict = Dictionary.create
list = List.create
mat3 = Mat3.create
spatial = Spatial.create
transform = Transform.create
atlas = Atlas.create
hsv = HSV

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

function gfx.prerender(w, h, f, ...)
    local args = {...}
    local prev_c = gfx.getCanvas()
    local c = gfx.newCanvas(w, h)
    gfx.setCanvas({c, stencil=true})
    gfx.push()
    gfx.origin()
    f(w, h, unpack(args))
    gfx.pop()
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
    return Color.create(unpack(splitToRGB))
end

function add(a, b) return a + b end
function sub(a, b) return a - b end
function dot(a, b) return a * b end


function errorf(...)
    error(string.format(...))
end

function printf(...)
    print(string.format(...))
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

function math.clamp(value, min, max)
    return math.max(min, math.min(value, max))
end

function math.atan2(x, y)
    local e = 1e-10

    if x > e then
        return math.atan(y / x)
    elseif x < -e and y >= e then
        return math.atan(y / x) + math.pi
    elseif x < -e and y < -e then
        return math.atan(y / x) - math.pi
    elseif math.abs(x) < e and y > e then
        return math.pi * 0.5
    elseif math.abs(x) < e and y < -e then
        return -math.pi * 0.5
    else
        return 0
    end
end

function class()
    local c = {}
    c.__index = c

    function c:class() return c end

    return c
end

function decorate(dst, src, overwrite)
    for key, value in pairs(src) do
        local is_function = type(value) == "function"
        if is_function then
            if not dst[key] or overwrite then
                dst[key] = value
            else
                errorf("Tried to decorate key %s to table, but was already set", key)
            end
        end
    end
end

function inherit(c, this)
    local i = setmetatable(this or {}, c)
    i.__index = i

    function i:class() return i end
    function i:superclass() return c end

    return i
end
