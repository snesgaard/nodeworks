local nw = require "nodeworks"
local T = nw.third.knife.test
local parent = nw.system.parent()

T("parenting", function(T)
    local ecs_world = nw.ecs.entity.create()
    local foo = ecs_world:entity()
    local bar = ecs_world:entity()
    local baz = ecs_world:entity()

    T("single_child", function(T)
        parent.set_parent(bar, foo)
        T:assert(parent.get_parent(foo) == nil)
        T:assert(parent.get_parent(bar) == foo.id)

        T:assert(parent.get_children(foo):keys() == list(bar.id))
        T:assert(parent.get_children(bar):keys() == list())

        T("remove", function(T)
            parent.set_parent(bar)
            
            T:assert(parent.get_parent(foo) == nil)
            T:assert(parent.get_parent(bar) == nil)

            T:assert(parent.get_children(foo):keys() == list())
            T:assert(parent.get_children(bar):keys() == list())
        end)
    end)

    T("two_children", function(T)
        parent.set_parent(bar, foo)
        parent.set_parent(baz, foo)

        T:assert(parent.get_children_in_order(foo) == list(bar.id, baz.id))
    end)

    T("change_parent", function(T)
        parent.set_parent(bar, foo)
        parent.set_parent(bar, baz)

        T:assert(parent.get_parent(foo) == nil)
        T:assert(parent.get_parent(bar) == baz.id)
        T:assert(parent.get_parent(baz) == nil)

        T:assert(parent.get_children_in_order(foo) == list())
        T:assert(parent.get_children_in_order(bar) == list())
        T:assert(parent.get_children_in_order(baz) == list(bar.id))
    end)
end)
