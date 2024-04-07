---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"
---@module "list"
local list = require "nodeworks.core.list"

local stack = nw.ecs.stack
local tf = nw.system.tf

local function get_matrix(id)
    return {tf.entity(id):getMatrix()}
end

local function is_approx_equal(a, b, t)
    return (t or 1e-5) >= math.abs(a - b)
end

local function is_close(a, b, t)
    return list.compare(a, b, is_approx_equal, t)
end


T("tf", function(T)
    stack.clear()
    local id = "subject"

    T("translation", function(T)
        local x, y = 10, 20
        stack.set(nw.component.position, id, x, y)
    
        local expected_matrix = {
            1, 0, 0, x,
            0, 1, 0, y,
            0, 0, 1, 0,
            0, 0, 0, 1
        }
        T:assert(is_close(get_matrix(id), expected_matrix))
    end)

    T("rotation", function(T)
        local angle = math.pi
        stack.set(nw.component.rotation, id, angle)
    
        local expected_matrix = {
            math.cos(angle), -math.sin(angle), 0, 0,
            math.sin(angle), math.cos(angle), 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        }
        T:assert(is_close(get_matrix(id), expected_matrix))
    end)

    T("scale", function(T)
        stack.set(nw.component.mirror, id, true)
        local expected_matrix = {
            -1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        }
    
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