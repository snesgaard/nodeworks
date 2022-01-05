local nw = require "nodeworks"
local T = nw.third.knife.test

local components = {}

function components.a() return 1 end
function components.b() return 2 end

T("system", function(T)
    local system_a = nw.ecs.system(components.a, components.b)
    local system_b = nw.ecs.system(components.b)

    local entity_a = nw.ecs.entity():set(components.a):set(components.b)
    local entity_b = nw.ecs.entity():set(components.b)
    local entity_c = nw.ecs.entity()

    T("entity_filter", function(T)
        T:assert(system_a.entity_filter(entity_a))
        T:assert(not system_a.entity_filter(entity_b))
        T:assert(not system_a.entity_filter(entity_c))

        T:assert(system_b.entity_filter(entity_a))
        T:assert(system_b.entity_filter(entity_b))
        T:assert(not system_b.entity_filter(entity_c))
    end)
end)
