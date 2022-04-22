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

        a:emit("a"):emit("a")
        b:emit("b")

        local d = c:pop()

        T:assert(d:size() == 3)
        T:assert(d[1] == "a")
        T:assert(d[2] == "a")
        T:assert(d[3] == "b")
    end)
end)
