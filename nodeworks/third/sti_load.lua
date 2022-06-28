local function tile_to_world_pos(map, layer, x, y)
    local px, py = map:convertTileToPixel(x - 1, y - 1)
    return px + layer.offsetx, py + layer.offsety
end

local function handle_layer_data(map, layer, tile_load, ...)
    if not layer.data or not tile_load then return end

    local entities = list()

    for y, row in ipairs(layer.data) do
        for x, tile in pairs(row) do
            local px, py = tile_to_world_pos(map, layer, x, y)
            local entity = tile_load(
                map, layer, tile,  px, py, ...)
            if entity then table.insert(entities, entity) end
        end
    end

    return entities
end

local function handle_layer_chunks(map, layer, tile_load, ...)
    if not layer.chunks or not tile_load then return end

    local entities = list()

    for _, chunk in ipairs(layer.chunks) do
        for y, row in ipairs(chunk.data) do
            for x, tile in pairs(row) do
                local px, py = tile_to_world_pos(
                    map, layer, x + chunk.x, y + chunk.y
                )
                local entity = tile_load(map, layer, tile, px, py, ...)
                if entity then table.insert(entities, entity) end
            end
        end
    end

    return entities
end

local function handle_tile_layer(map, layer, tile_load, ...)
    local data_entities = handle_layer_data(map, layer, tile_load, ...)
    local chunk_entities = handle_layer_chunks(map, layer, tile_load, ...)

    if not data_entities then return chunk_entities end
    if not chunk_entities then return data_entities end

    return data_entities + chunk_entities
end

local function handle_object_layer(sti_map, layer, object_load, ...)
    local entities = {}
    for _, object in ipairs(layer.objects) do
        local entity = object_load(sti_map, layer, object, ...)
        if entity then table.insert(entities, entity) end
    end

    return entities
end

local function handle_layer(sti_map, layer, tile_load, object_load, ...)
    if layer.type == "tilelayer" then
        return handle_tile_layer(sti_map, layer, tile_load, ...)
    elseif layer.type == "objectgroup" then
        layer.visible = false
        return handle_object_layer(sti_map, layer, object_load, ...)
    end
end

return function(map, tile_load, object_load, ...)
    for _, layer in ipairs(map.layers) do
        handle_layer(map, layer, tile_load, object_load, ...)
    end
end
