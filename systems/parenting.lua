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

function system.parent(entity) return entity[components.parent] end

function system.lineage(entity)
    local lineage = list()
    local e = entity

    while e do
        table.insert(lineage, e)
        e = e[components.parent]
    end

    return lineage
end

function system.is_child(entity)
    return entity[components.parent]
end

local function read_position(entity) return entity[components.position] or vec2() end

local function add(a, b) return a + b end

function system.world_position(entity)
    local lineage = system.lineage(entity)

    local position = lineage
        :map(read_position)
        :reduce(add, vec2())

    return position
end

function system.find_first(entity, component)
    local node = entity
    while node do
        local c = node[component]
        if c then return c end
        node = node[components.parent]
    end
end

function system:debug_draw()
    for _, entity in ipairs(self.pool) do
        local parent = system.parent(entity)
        if parent then
            local p1 = system.world_position(parent)
            local p2 = system.world_position(entity)
            gfx.line(p1.x, p1.y, p2.x, p2.y)
            gfx.circle("fill", p2.x, p2.y, 6)
            gfx.rectangle("fill", p1.x - 3, p1.y - 3, 6, 6)
        end
    end
end

return system
