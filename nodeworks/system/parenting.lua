local function children_component(...) return list(...) end

local function adopt(parent, child)
    table.insert(parent:ensure(children_component), child)
end

local function orphan(parent, child)
    local children = parent[children_component]
    if not children then return end
    local index = List.argfind(children, child)
    table.remove(children, index)
    if #children == 0 then parent[children_component] = nil end
end


local system = ecs.system(components.parent)

function system:on_entity_added(entity)
    adopt(entity[components.parent], entity)
end

function system:on_entity_updated(entity, pool, component, prev_parent)
    if component == components.parent then
        orphan(prev_parent, entity)
        adopt(entity[components.parent], entity)
    end
end

function system:on_entity_removed(entity, pool, component, prev_parent)
    if component == components.parent then
        orphan(prev_parent, child)
    else
        orphan(entity[components.parent], entity)
    end
end

function system:on_entity_destroyed(entity)
    for _, child in ipairs(entity[children_component] or {}) do
        orphan(entity, child)
        child:destroy()
    end
end

function system.children(entity) return entity[children_component] or list() end

function system.lineage(entity)
    local lineage = list()
    local e = entity

    while e do
        table.insert(lineage, e)
        e = e[components.parent]
    end

    return lineage
end

return system
