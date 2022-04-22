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
        T:assert(reduce:get() == 0)

        collect
            :emit{1}
            :emit{4}
            :emit{6}
            :emit{7}

        T:assert(reduce:get() == 2)
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
        T:assert(unpack(d[1]) == "a")
        T:assert(unpack(d[2]) == "a")
        T:assert(unpack(d[3]) == "b")
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
end)
