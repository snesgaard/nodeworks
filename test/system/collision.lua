local stack = nw.ecs.stack
local collision = nw.system.collision
local event = nw.system.event

T("test_collision", function(T)
    stack.reset()

    local id = "foo"
    local id2 = "bar"

    collision
        .register(id, spatial(0, 0, 10, 10))
        .register(id2, spatial(100, 0, 10, 10))

    T:assert(collision.get_bump_world():countItems() == 2)

    T("move", function(T)
        local ax, ay, cols = collision.move_to(id, 1000, 0, function() return "cross" end)
        T:assert(#cols == 1)
        local colinfo = unpack(cols)
        T:assert(colinfo.type == "cross")
    
        event.spin()
        T:assert(event.get("move"):size() == 1)
    end)

    T("move_and_collide", function(T)
        local ax, ay, cols = collision.move_to(id, 1000, 0, function() return "slide" end)
        T:assert(#cols == 1)
        local colinfo = unpack(cols)
        T:assert(colinfo.type == "slide")
        T:assert(ax == 90)
        T:assert(ay == 0)
        local pos = stack.ensure(nw.component.position, id)
        T:assert(pos.x == ax)
        T:assert(pos.y == ay)
    end)

    T("move", function(T)
        local pos = stack.ensure(nw.component.position, id)
        local dx, dy, cols = collision.move(id, 10, 20, function() return "cross" end)
        T:assert(#cols == 0)
        T:assert(dx == 10)
        T:assert(dy == 20)
        local next_pos = stack.ensure(nw.component.position, id)
        T:assert(pos.x + dx == next_pos.x)
        T:assert(pos.y + dy == next_pos.y)
    end)

    T("world_hitbox", function(T)
        collision.warp_to(id, 200, 300)
        local x, y, w, h = collision.get_world_hitbox(id)
        T:assert(x == 200)
        T:assert(y == 300)
        T:assert(w == 10)
        T:assert(h == 10)
    end)

    T("world_hitbox_offset", function(T)
        local id3 = {}
        collision
            .register(id3, spatial(1, 2, 3, 4))
            .warp_to(id3, 100, 200)
        local x, y, w, h = collision.get_world_hitbox(id3)
        T:assert(x == 100 + 1)
        T:assert(y == 200 + 2)
        T:assert(w == 3)
        T:assert(h == 4)

        stack.destroy(id3)
    end)

    T("garbage_collection", function(T)
        stack.destroy(id2)
        local ax, ay, cols = collision.move_to(id, 1000, 0, function() return "cross" end)
        T:assert(#cols == 0)
        
        collectgarbage()
        T:assert(collision.get_bump_world():countItems() == 1)    
    end)

    T("flipping", function(T)
        collision.warp_to(id, 0, 0).flip_to(id, true)
        T:assert(stack.get(nw.component.mirror, id))
        T:assert(spatial(collision.get_world_hitbox(id)) == spatial(-10, 0, 10, 10))
        collision.flip(id)
        T:assert(not stack.get(nw.component.mirror, id))
        T:assert(spatial(collision.get_world_hitbox(id)) == spatial(0, 0, 10, 10))
    end)
end)