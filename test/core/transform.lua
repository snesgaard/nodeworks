T("transform", function(T)
    local t = transform(1, 2, -4, 8)
    T:assert(t.x == 1)
    T:assert(t.y == 2)
    T:assert(t.sx == -4)
    T:assert(t.sy == 8)

    local identity = t * t:invert()

    T:assert(identity.x == 0)
    T:assert(identity.y == 0)
    T:assert(identity.sx == 1)
    T:assert(identity.sy == 1)

    local identity = t:invert() * t

    T:assert(identity.x == 0)
    T:assert(identity.y == 0)
    T:assert(identity.sx == 1)
    T:assert(identity.sy == 1)
end)