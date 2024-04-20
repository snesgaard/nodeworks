---@module "3rd"
local third = require "3rd"
---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.component"
local component = require "nodeworks.component"

local map = {}

function map.load_tile_layer(layer_id, layer)
    if layer.type ~= "tilelayer" then return end

    stack.set(component.tile_layer, layer_id, layer)
end


---@param path string
---@return Id
function map.load_tiled(path)
    local tiled_map = third.sti(path)

    for index, tiled_layer in ipairs(tiled_map.layers) do
        map.load_tile_layer(index, tiled_layer)
    end
end

function map.view_layers()
    return ipairs({})
end

return map