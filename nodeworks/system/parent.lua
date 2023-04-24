local nw = require "nodeworks"

local Parent = nw.system.base()

local component = {}

component.children = nw.component.relation(function(num) return num end)

function component.parent(parent) return parent end

function component.child_order_number(v) return v or 0 end

function Parent.set_parent(child, parent)
    local prev_parent = child:get(component.parent)

    if parent == prev_parent then return end

    if prev_parent then
        child:remove(component.children:ensure(prev_parent))
    end
    if parent then
        local order_num = parent:ensure(component.child_order_number)
        parent:set(component.child_order_number, order_num + 1)


        child:set(component.parent, parent.id)
        child:set(component.children:ensure(parent.id), order_num)
    else
        child:remove(component.parent)
    end
end

function Parent.get_children(entity)
    local pc = component.children:ensure(entity.id)
    return entity:world():get_component_table(pc)
end

function Parent.get_children_in_order(entity)
    local children_table = Parent.get_children(entity)
    return children_table
        :keys()
        :sort(function(a, b) return children_table[a] < children_table[b] end)
end

function Parent.get_parent(entity) return entity:get(component.parent) end

function Parent.spawn(entity, id)
    return entity:world():entity(id)
        :assemble(Parent.set_parent, entity)
end

function Parent.destroy(entity)
    local children = Parent.get_children(entity)
    for id, _ in pairs(children) do
        local e = entity:world():entity(id)
        print("destroy child", e)
        Parent.destroy(e)
    end
    entity:destroy()
end

return Parent.from_ctx
