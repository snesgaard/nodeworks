---@module "3rd"
local third = require "3rd"
---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.system.collision"
local collision = require "nodeworks.system.collision"
---@module "nodeworks.core.spatial"
local spatial = require "nodeworks.core.spatial"
---@module "nodeworks.ecs.id"
local ecs_id = require "nodeworks.ecs.id"

local map = {}

---@param id Id
---@param properties table<string, any>
function map.tile_properties(id, properties) end

function map.load_tile_layer(layer_id, layer)
    if layer.type ~= "tilelayer" then return end

    stack.set(component.tile_layer, layer_id, layer)

    if layer.parallaxx ~= 1 or layer.parallaxy ~= 1 then return end

    for _, chunk in ipairs(layer.chunks) do
        chunk.ids = {}
        for y, row in pairs(chunk.data) do
            for x, tile in pairs(row) do
                local id = ecs_id.weak("tile")
                collision.register(id, spatial(0, 0, tile.width, tile.height))
                collision.warp_to(
                    id, layer.offsetx + (chunk.x + x - 1) * tile.width,
                    layer.offsety + (chunk.y + y - 1) * tile.height
                )

                local p = map.tile_properties(id, tile.properties)

                table.insert(chunk.ids, id)
            end
        end
    end    
end

function map.load_image_layer(layer_id, layer)
    if layer.type ~= "imagelayer" then return end

    stack.set(component.image_layer, layer_id, layer)
end

---@param id Id
---@param object table<string, any>
---@return table|nil
function map.object_properties(id, object)

end

function map.load_object_layer(layer_id, layer)
    if layer.type ~= "objectgroup" then return end

    stack.set(component.object_layer, layer_id, layer)

    layer.ids = {}
    for _, object in ipairs(layer.objects) do
        local id = ecs_id.weak("object")

        stack.assemble(
            {
                {component.position, layer.offsetx, layer.offsety}
            },
            id
        )

        map.object_properties(id, object)
        table.insert(layer.ids, id)
    end
end


---@param path string
---@return Id
function map.load_tiled(path)
    local tiled_map = third.sti(path)

    for index, tiled_layer in ipairs(tiled_map.layers) do
        local layer_id = index
        map.load_tile_layer(layer_id, tiled_layer)
        map.load_image_layer(layer_id, tiled_layer)
        map.load_object_layer(layer_id, tiled_layer)

        stack.assemble(
            {
                {component.layer, index},
                {component.parallax, tiled_layer.parallaxx, tiled_layer.parallaxy},
                {component.position, tiled_layer.offsetx, tiled_layer.offsety}
            },
            layer_id
        )
        stack.set(component.layer, layer_id, index)
    end
end

---@param a Id
---@param b Id
---@return boolean
local function compare_layers(a, b)
    return stack.get_or_default(component.layer, a, 0) < stack.get_or_default(component.layer, b, 0)
end

function map.view_layers()
    local layers = {}

    for id, _ in stack.view_table(component.tile_layer) do
        table.insert(layers, id)
    end

    for id, _ in stack.view_table(component.image_layer) do
        table.insert(layers, id)
    end

    for id, _ in stack.view_table(component.object_layer) do
        table.insert(layers, id)
    end

    table.sort(layers, compare_layers)

    return ipairs(layers)
end

return map