local function project_onto_circle(x, y, cx, cy, radius)
    local dx = x - cx
    local dy = y - cy
    local l_square = dx * dx + dy * dy
    if l_square <= radius * radius then return x, y end

    local l = math.sqrt(l_square) + 1e-10

    return dx * radius / l + cx, dy * radius / l + cy
end

local function project_onto_rectangle(x, y, rx, ry, w, h)
    return math.clamp(x, rx, rx + w), math.clamp(y, ry + h)
end

local function project_onto_boundry(fx, fy, lx, ly, leash, leash_type)
    if leash_type == "circle" then
        return project_onto_circle(fx, fy, lx, ly, leash)
    elseif leash_type == "rectangle" then
        local l = leash
        return project_onto_rectangle(fx, fy, lx - l, ly - l, 2 * l, 2 * l)
    else
        return lx, ly
    end
end

local function follow_entity_next_position(follower_id, leader_id, leash, leash_type)
    local fx, fy = stack.ensure(nw.component.position, follower_id):unpack()
    local lx, ly = stack.ensure(nw.component.position, leader_id):unpack()
    local leash = math.max(leash or 0, 0)

    local px, py = project_onto_boundry(fx, fy, lx, ly, leash, leash_type)

    if px == nil then
        errorf(
            "Failed to project onto follow boundry: follower %s, leader %s, leash_type %s",
            tostring(follower_id), tostring(leader_id), tostring(leash_type)
        )
    end

    return px, py
end

local follow = {}

function follow.compute_follower_position(follower_id, leader_id, leash, leash_type, max_move)
    local follower_pos
end

function follow.update(dt)
    for follower_id, leader_id in stack.view_table(nw.component.is_following) do
        local px, py = follow_entity_next_position(follower_id, leader_id)
        nw.system.collision.move_to(follower_id, px, py)
    end
end

function follow.spin()
    for _, dt in event.view("update") do follow.update(dt) end
end

return follow