local nw = require "nodeworks"

local collision = nw.system.collision

local empty_list = list()

local function load_tilelayer(index, layer, tile_properties)
    if layer.type ~= "tilelayer" then return end

    -- Do not create collision for parallaxx layers, as the collision cannot handle that.
    -- Also parallax is background which we do not want to interact with.
    if layer.parallaxx ~= 1 or layer.parallaxy ~= 1 then return end

    for _, chunk in ipairs(layer.chunks) do
        chunk.ids = list()
        for y, row in pairs(chunk.data) do
            for x, tile in pairs(row) do
                local id = nw.ecs.id.weak("tile")
                collision.register(id, spatial(0, 0, tile.width, tile.height))
                collision.warp_to(
                    id, layer.offsetx + (chunk.x + x - 1) * tile.width,
                    layer.offsety + (chunk.y + y - 1) * tile.height
                )

                if tile_properties then
                    local components = tile_properties(tile.properties) or empty_list
                    stack.assemble(components, id)
                end

                table.insert(chunk.ids, id)
            end
        end
    end
end

local function load_object(object, index, layer)
    stack.assemble(
        {
            {collision.register, object.id, spatial(0, 0, object.width, object.height)},
            {collision.warp_to, object.id, object.x + layer.offsetx, object.y + layer.offsety}
        },
        object.id
    )

    return object.id
end

local function load_objectgroup(index, layer)
    if layer.type ~= "objectgroup" then return end

    layer.entities = list()

    layer.ids = list()
    for _, object in ipairs(layer.objects) do
        local id = load_object(object, index, layer)
        if id then 
            stack.assemble(
                {
                    {nw.component.layer, index}
                },
                id
            )
            table.insert(layer.ids, id)
        end
    end
end

local function load_imagelayer(index, layer, id)
    if layer.type ~= "imagelayer" then return end

    stack.set(nw.component.wrap_mode, id, layer.repeatx, layer.repeaty)
    stack.set(nw.component.image, id, layer.image)
end

local tiled = {}

function tiled.tile_properties(properties) end

local function layer_color(color)
    if not color then return 1, 1, 1 end

    local r, g, b, a = unpack(color)
    return (r or 255) / 255.0, (g or 255) / 255.0, (b or 255) / 255.0, (a or 255) / 255.0
end

local function drawable_from_layer_type(layer_type)
    if layer_type == "tilelayer" then
        return nw.drawable.tiled_layer
    elseif layer_type == "imagelayer" then
        return nw.drawable.scrolling_texture
    end
end

function tiled.load(path)
    local map = nw.third.sti(path)

    for index, layer in ipairs(map.layers) do
        print("loading layer", layer.name)
        local id = layer

        load_tilelayer(index, layer, tiled.tile_properties)
        load_objectgroup(index, layer)
        load_imagelayer(index, layer, id)

        stack.assemble(
            {
                {nw.component.layer, index},
                {nw.component.tiled_layer, layer},
                {nw.component.drawable, drawable_from_layer_type(layer.type)},
                {nw.component.hidden, not layer.visible or layer.type == "objectgroup"},
                {nw.component.parallax, layer.parallaxx, layer.parallaxy},
                {nw.component.position, layer.offsetx, layer.offsety},
                {
                    nw.component.color, layer_color(layer.tintcolor)
                }
            },
            id
        )
    end

    return map
end

return tiled