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
Spatial = require(BASE .. ".spatial")
Transform = require(BASE .. ".transform")
vec2 = require(BASE .. ".vec2")
particles = require(BASE .. ".particles")
ease = require(BASE .. ".ease")
bump_debug = require(BASE .. ".bump_debug")
draw_node = require(BASE .. ".draw_node")

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
atlas = Atlas.create
