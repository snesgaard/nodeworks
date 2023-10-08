local tf = nw.system.tf

local function get_matrix(id)
    return list(tf.entity(id):getMatrix())
end

local function is_close(a, b, t)
    local t = t or 1e-5
    if a:size() ~= b:size() then return false end

    for i = 1, a:size() do
        if t < math.abs(a[i] - b[i]) then return false end
    end

    return true
end

T("tf", function(T)
    stack.reset()
    local id = "subject"

    T("translation", function(T)
        local x, y = 10, 20
        stack.set(nw.component.position, id, x, y)
    
        local expected_matrix = list(
            1, 0, 0, x,
            0, 1, 0, y,
            0, 0, 1, 0,
            0, 0, 0, 1
        )
        T:assert(is_close(get_matrix(id), expected_matrix))
    end)

    T("rotation", function(T)
        local angle = math.pi
        stack.set(nw.component.rotation, id, angle)
    
        local expected_matrix = list(
            math.cos(angle), -math.sin(angle), 0, 0,
            math.sin(angle), math.cos(angle), 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        )
        T:assert(is_close(get_matrix(id), expected_matrix))
    end)

    T("scale", function(T)
        local sx, sy = 2, 3
        stack.set(nw.component.scale, id, sx, sy)
        local expected_matrix = list(
            sx, 0, 0, 0,
            0, sy, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        )
    
        T:assert(is_close(get_matrix(id), expected_matrix))
    end)

    T("origin", function(T)
        local ox, oy = 4, 5
        stack.set(nw.component.origin, id, ox, oy)

        local expected_matrix = list(
            1, 0, 0, -ox,
            0, 1, 0, -oy,
            0, 0, 1, 0,
            0, 0, 0, 1
        )
        T:assert(is_close(get_matrix(id), expected_matrix))
    end)

    T("transforms", function(T)
        local x, y = 10, 20
        stack.set(nw.component.position, id, x, y)
        local t = tf.entity(id)

        local ox, oy = tf.transform_origin(t)
        T:assert(ox == 10)
        T:assert(oy == 20)

        local rx, ry, rw, rh = tf.transform_rectangle(t, 1, 2, 3, 4)
        T:assert(rx == 11)
        T:assert(ry == 22)
        T:assert(rw == 3)
        T:assert(rh == 4)
    end)

end)