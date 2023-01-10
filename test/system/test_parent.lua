local nw = require "nodeworks"
local T = nw.third.knife.test
local parent = nw.system.parent()

T("parenting", function(T)
    local ecs_world = nw.ecs.entity.create()

    local c = ecs_world:entity()
    local p1 = ecs_world:entity()
    local p2 = ecs_world:entity()

    T:assert(parent.children(c):size() == 0)
    T:assert(parent.children(p1):size() == 0)
    T:assert(parent.children(p2):size() == 0)

    c:assemble(parent.set_parent, p1)

    T:assert(parent.get_parent(c) == p1)
    T:assert(parent.children(p1):size() == 1)
    T:assert(parent.children(p1)[c])

    T("orphan", function(T)
        c:assemble(parent.set_parent)

        T:assert(not parent.get_parent(c))
        T:assert(parent.children(p1):size() == 0)
        T:assert(not parent.children(p1)[c])
    end)

    T("adopt", function(T)
        c:assemble(parent.set_parent, p2)

        T:assert(parent.get_parent(c) == p2)

        T:assert(parent.children(p1):size() == 0)
        T:assert(not parent.children(p1)[c])

        T:assert(parent.children(p2):size() == 1)
        T:assert(parent.children(p2)[c])
    end)

    T("die_with_parent", function(T)
        c:set(nw.component.die_with_parent)

        p1:destroy()

        T:assert(not c:get(nw.component.die_with_parent))
    end)

    T("second child", function(T)
        local c2 = ecs_world:entity()
            :assemble(parent.set_parent, p1)

        T:assert(parent.children(p1):size() == 2)
        T:assert(parent.children(p1)[c])
        T:assert(parent.children(p1)[c2])
    end)
end)
