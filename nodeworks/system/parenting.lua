local nw = require "nodeworks"

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


local system = nw.ecs.system(nw.component.parent)

function system.on_entity_added(world, entity)
    adopt(entity[nw.component.parent], entity)
end

function system.on_entity_changed(world, entity, prev_state)
    local prev_parent = prev_state[nw.component.parent]
    local next_parent = entity[nw.component.parent]
    if prev_parent then orphan(prev_parent, entity) end
    if next_parent then adopt(next_parent, entity) end
end

function system.on_entity_removed(world, entity, prev_state)
    local parent = entity[nw.component.parent] or prev_state[nw.component.parent]
    if parent then
        orphan(parent, entity)
    end
end

--[[ Refactor with an explicit destruction component
function system:on_entity_destroyed(entity)
    for _, child in ipairs(entity[children_component] or {}) do
        orphan(entity, child)
        child:destroy()
    end
end
]]--

function system.children(entity) return entity[children_component] or list() end

function system.lineage(entity)
    local lineage = list()
    local e = entity

    while e do
        table.insert(lineage, e)
        e = e[nw.component.parent]
    end

    return lineage
end

return system
