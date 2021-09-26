gfx = love.graphics
rng = love.math.random

local BASE = ...

math = require "math"
json = require(BASE .. ".third.json")
log = require(BASE .. ".third.log")
lume = require(BASE .. ".third.lume")
lurker = require(BASE .. ".third.lurker")
moon = require (BASE .. ".third.moonshine")
sti = require(BASE .. ".third.Simple-Tiled-Implementation.sti")
render_graph = require(BASE .. ".render_graph")
require (BASE .. ".third.patch")

ecs = require(BASE .. ".ecs")
core = require(BASE .. ".core")
require(BASE .. ".scene")
require(BASE .. ".event")

components = require(BASE .. ".components")
systems = require(BASE .. ".systems")

event = event_server()

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
    return list(unpack(splitToRGB))
end

function rgb(r, g, b) return rgba(r, g, b, 255.0) end
function rgba(r, g, b, a) return {r / 255.0, g / 255.0, b / 255.0, a / 255.0} end
function vec4(r, g, b, a) return {r or 1, g or 1, b or 1, a or 1} end

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

function math.sign(value)
    if value < -1e-10 then
        return -1
    elseif value > 1e-10 then
        return 1
    else
        return 0
    end
end

function math.remap(value, prev_min, prev_max, next_min, next_max)
    local x = (value  - prev_min) / (prev_max - prev_min)

    return x * (next_max - next_min) + next_min
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
        path:gsub("%.%./", "/__parent/"), '/'
    )
end

function string.stack(a, b, ...)
    if not a or not b then
        return a
    else
        return string.stack(a .. "\n" .. b, ...)
    end
end

local font_cache = {}

function font(size)
    if not font_cache[size] then
        font_cache[size] = gfx.newFont(size)
    end
    return font_cache[size]
end

function join(a, b, ...)
    if not b then return a end

    return join(string.format("%s/%s", a, b), ...)
end


function errorf(...)
    error(string.format(...))
end

function printf(...)
    print(string.format(...))
end

function add(a, b) return a + b end
function sub(a, b) return a - b end
function dot(a, b) return a * b end

gfx.setDefaultFilter("nearest", "nearest")

return {
    component=components, system=systems,
    sti=sti, ecs=ecs, ease=ease
}
