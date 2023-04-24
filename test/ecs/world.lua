local component = {}

function component.foo(v) return v or 0 end

function component.bar(v) return (v or 0) + 1 end

function component.tar(v) return {value = v or 0} end

T("test_world", function(T)
    local world = nw.ecs.world()

    T("test_get_set", function(T)
        local id = "yesman"

        T:assert(world:get(component.foo, id) == nil)
        
        world:set(component.foo, id)
        T:assert(world:get(component.foo, id) == component.foo())

        world:set(component.foo, id, 22)
        T:assert(world:get(component.foo, id) == component.foo(22))

        world:set(component.bar, id, 23)
        T:assert(world:get(component.bar, id) == component.bar(23))
    end)

    T("test ensure", function(T)
        local id = "yesman"
        local v = 23

        T:assert(world:ensure(component.foo, id, v) == component.foo(v))
        T:assert(world:ensure(component.foo, id, v + 1) == component.foo(v))
    end)

    T("test_has", function(T)
        local id = "yesman"

        T:assert(not world:has(component.foo, id))
        world:set(component.foo, id)
        T:assert(world:has(component.foo, id))
    end)

    T("test_init", function(T)
        local id = "yesman"

        world:init(component.foo, id, 23):init(component.foo, id)

        T:assert(world:get(component.foo, id) == component.foo(23))
    end)

    T("test_gc", function(T)
        local weak_id = {}
        local strong_id = "yes"

        world:set(component.foo, weak_id)
        world:set(component.foo, strong_id)
        T:assert(world:get_table(component.foo):size() == 2)

        weak_id = nil
        collectgarbage()
        T:assert(world:get_table(component.foo):size() == 1)
    end)

    T("test_copy", function(T)
        local id = "yes"
        local id2 = "no"

        world
            :set(component.foo, id)
            :set(component.foo, id2, 1)

        local next_world = world:copy()
        T:assert(next_world:get_table(component.foo) == world:get_table(component.foo))
        
        next_world:set(component.foo, id, 23)
        T:assert(next_world:get_table(component.foo) ~= world:get_table(component.foo))
        T:assert(next_world:get(component.foo, id) ~= world:get(component.foo, id))
        T:assert(next_world:get(component.foo, id2) == world:get(component.foo, id2))
    end)

    T("test_copy_deep", function(T)
        local id = "yes"

        world:set(component.tar, id)
        local next_world = world:copy():set(component.tar, id, 2)

        T:assert(world:get(component.tar, id) ~= next_world:get(component.tar, id))
        T:assert(world:get(component.tar, id).value == 0)
        T:assert(next_world:get(component.tar, id).value == 2)
    end)

    T("test_destroy", function(T)
        local id = "yes"

        world:set(component.tar, id):set(component.foo, id)
        world:destroy(id)
        T:assert(not world:has(component.tar, id))
        T:assert(not world:has(component.foo, id))
    end)

    T("test_remove", function(T)
        local id = "yes"
        world:set(component.tar, id):remove(component.tar, id)
        T:assert(not world:has(component.tar, id))
    end)

    T("visit", function(T)
        local id = "foo"

        local function visiter(self, id)
            self
                :set(component.tar, id)
                :set(component.bar, id)
                :set(component.foo, id)
        end

        world:visit(visiter, id)
    end)

    T("assemble", function(T)
        local values = {
            {component.tar},
            {component.bar},
            {component.foo}
        }

        world:assemble(values, "yes")

        T:assert(world:has(component.tar, "yes"))
        T:assert(world:has(component.bar, "yes"))
        T:assert(world:has(component.foo, "yes"))
    end)
end)