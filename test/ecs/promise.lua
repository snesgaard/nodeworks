local nw = require "nodeworks"
local T = nw.third.knife.test

T("promise", function(T)
    local collect = nw.ecs.promise.collect()

    T("emit single", function(T)
        T:assert(collect:peek():size() == 0)
        collect:emit{"this is an event"}
        T:assert(collect:peek():size() == 1)
        T:assert(collect:pop():size() == 1)
        T:assert(collect:peek():size() == 0)
    end)

    local filter = collect
        :filter(function(a) return a < 5 end)
        :collect()


    T("emit filter", function(T)
        collect
            :emit{1}
            :emit{4}
            :emit{6}
            :emit{7}

        T:assert(collect:peek():size() == 4)
        T:assert(filter:peek():size() == 2)
    end)

    local reduce = filter:reduce(function(v) return v + 1 end, 0)

    T("reduce", function(T)
        T:assert(reduce:peek() == 0)

        collect
            :emit{1}
            :emit{4}
            :emit{6}
            :emit{7}

        T:assert(reduce:peek() == 2)
    end)

    T("garbage_child", function(T)
        local parent = nw.ecs.promise.collect()
        local child = parent:filter(function() end)
        T:assert(#parent.children == 1)
        child = nil
        collectgarbage()
        T:assert(#parent.children == 0)
    end)

    T("garbage_parent", function(T)
        local parent = nw.ecs.promise.collect()
        local child = parent:filter(function() end)
        T:assert(#child.parents == 1)
        parent = nil
        collectgarbage()
        T:assert(#child.parents == 1)
    end)

    T("merge", function(T)
        local a = nw.ecs.promise.observable()
        local b = nw.ecs.promise.observable()
        local c = a:merge(b):collect()

        a:emit{"a"}:emit{"a"}
        b:emit{"b"}

        local d = c:pop()

        T:assert(d:size() == 3)
        T:assert(d[1] == "a")
        T:assert(d[2] == "a")
        T:assert(d[3] == "b")
    end)

    T("latest", function(T)
        local a = nw.ecs.promise.observable()
        local b = a:latest()

        a:emit{1}:emit{2}:emit{3}

        T:assert(b:peek() == 3)
    end)

    T("map", function(T)
        local a = nw.ecs.promise.observable()
        local b = a:map(function(s) return s * 2 end):latest()

        a:emit{3}
        T:assert(b:peek() == 6)

        a:emit{6}
        T:assert(b:peek() == 12)
    end)

    T("caching", function(T)
        local a = nw.ecs.promise.observable()
        local b = a:latest()
        T:assert(b:peek() == nil)
        a:emit{1}
        T:assert(b:peek() == 1)
        local c = b:latest()
        T:assert(c:peek() == 1)
    end)

    T("caching_layered", function(T)
        local a = nw.ecs.promise.observable()
            :latest{1}
            :latest{2}
        local b = a:latest()
        T:assert(b:peek() == 2)
    end)

    T("caching_collect", function(T)
        local a = nw.ecs.promise.observable():latest{1}
        local b = a:collect()
        local c = b:latest()
        T:assert(b:peek():size() == 1)
        T:assert(c:peek() == 1)
    end)

    T("cache_then_emit", function(T)
        local a = nw.ecs.promise.observable():latest{1}
        local b = a:collect()
        for i = 2, 4 do a:emit{i} end
        T:assert(b:peek():size() == 4)
        local c = b:latest()
        T:assert(c:peek() == 4)
    end)

    T("cache_reduce", function(T)
        local a = nw.ecs.promise.observable()
            :reduce(function(a, b) return a + b end, 0)
        local b = a:latest()
        T:assert(b:peek() == 0)
        a:emit{1}
        a:emit{2}
        local c = a:latest()
        T:assert(c:peek() == 1 + 2)
    end)
end)
