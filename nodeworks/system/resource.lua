---@module "nodeworks.core.atlas"
local Atlas = require "nodeworks.core.atlas"

local resource = {
    _atlas_cache = {}
}

---@param path string
---@return Atlas
function resource.get_atlas(path)
    local prev_atlas = resource._atlas_cache[path]
    if prev_atlas then return prev_atlas end
    local a = Atlas.from_file(path)
    resource._atlas_cache[path] = a
    return a
end


return resource