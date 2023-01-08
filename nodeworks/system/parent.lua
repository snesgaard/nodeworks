local nw = require "nodeworks"

local Parent = nw.system.base()

local component = {}

function component.parent(p) return p end

function component.children(c) return c or dict() end

local function orphan(parent, child)
    if not parent or not child then return end

    local children = parent:ensure(component.children)
    if children[child] then
        child:remove(component.parent)
        children[child] = nil
    end

end

local function adopt(parent, child)
    if not parent or not child then return end

    local children = parent:ensure(component.children)
    children[child] = true
    child:set(component.parent, parent)

    local on_entity_destroyed = parent:world().on_entity_destroyed
    on_entity_destroyed.parent = on_entity_destroyed.parent or Parent.on_entity_destroyed
end

function Parent.on_entity_destroyed(id, destroyed_values, ecs_world)
    local children = destroyed_values[component.children]
    if not children then return end

    for child, _ in pairs(children) do
        if child:get(nw.component.die_with_parent) then
            child:destroy()
        end
    end
end

function Parent.set_parent(entity, parent)
    orphan(entity:get(component.parent), entity)
    adopt(parent, entity)
end

function Parent.get_parent(entity)
    return entity:get(component.parent)
end

function Parent.children(entity)
    return entity:ensure(component.children)
end

return Parent.from_ctx
