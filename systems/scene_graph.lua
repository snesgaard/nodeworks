local function remove_from_parent(entity, parent)
    parent = parent or entity[components.parent]
    if not parent then return end
    local children = parent[components.children] or {}
    if not children then return end
    local index = List.argfind(children, entity)
    print("what!", unpack(children), #children)
    if not index then return end
    for i = index, #children do children[i] = children[i + 1] end
end

local function add_to_parent(entity)
    local parent = entity[components.parent]
    if not parent then return end
    local children = parent:ensure(components.children)
    table.insert(children, entity)
end

local scene_graph_system = ecs.system(components.parent)

function scene_graph_system:on_entity_added(entity)
    add_to_parent(entity)
end

function scene_graph_system:on_entity_updated(entity, pool, component, prev_parent)
    print("previously!", prev_parent)
    remove_from_parent(entity, prev_parent)
    add_to_parent(entity)
end

function scene_graph_system:on_entity_removed(entity, pool, component, prev_parent)
    remove_from_parent(entity, prev_parent)
end

function scene_graph_system:on_entity_destroyed(entity)
    remove_from_parent(entity)

    local children = entity[components.children]
    if not children then return end
    entity:remove(components.children)
    for _, child in ipairs(children) do child:destroy() end
end

function scene_graph_system.root_path(entity)
    local path = {}
    while entity do
        table.insert(path, entity)
        entity = entity[components.parent]
    end
    return path
end


return scene_graph_system
