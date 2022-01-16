T("layout", function(T)
    local x, y, w, h = 0, 10, 100, 50

    local l = nw.nodegui.layout(x, y, w, h)

    T:assert(l.shape.x == x)
    T:assert(l.shape.y == y)
    T:assert(l.shape.w == w)
    T:assert(l.shape.h == h)

    T("up", function(T)
        l:up()

        T:assert(l.shape.x == x)
        T:assert(l.shape.y == y - h)
        T:assert(l.shape.w == w)
        T:assert(l.shape.h == h)
    end)

    T("down", function(T)
        l:down()

        T:assert(l.shape.x == x)
        T:assert(l.shape.y == y + h)
        T:assert(l.shape.w == w)
        T:assert(l.shape.h == h)
    end)

    T("left", function(T)
        l:left()

        T:assert(l.shape.x == x - w)
        T:assert(l.shape.y == y)
        T:assert(l.shape.w == w)
        T:assert(l.shape.h == h)
    end)

    T("right", function(T)
        l:right()

        T:assert(l.shape.x == x + w)
        T:assert(l.shape.y == y)
        T:assert(l.shape.w == w)
        T:assert(l.shape.h == h)
    end)

    T("push_pop", function(T)
        l:push()

        T:assert(#l.stack == 1)

        l:right():up()

        T:assert(l.shape.x ~= x)
        T:assert(l.shape.y ~= y)

        l:pop()

        T:assert(l.shape.x == x)
        T:assert(l.shape.y == y)
        T:assert(l.shape.w == w)
        T:assert(l.shape.h == h)
    end)
end)
