local BASE = ...

BASE = BASE == "init" and "" or BASE

require(BASE .. ".functional")

Atlas = require(BASE .. ".atlas")
Color = require(BASE .. ".color")
Dictionary = require(BASE ..  ".dictionary")
Frame = require(BASE .. ".frame")
require(BASE .. ".functional")
List = require(BASE .. ".list")
Mat3 = require(BASE .. ".mat3")
particles = require(BASE .. ".particles")
Spatial = require(BASE .. ".spatial")
State = require(BASE .. ".state")
Transform = require(BASE .. ".transform")
vec2 = require(BASE .. ".vec2")

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

color = Color.create
dict = Dictionary.create
list = List.create
mat3 = Mat3.create
spatial = Spatial.create
transform = Transform.create
