local camera = {}

function camera.push_transform(entity)
    local pos = entity % nw.component.position or vec2()
    local scale = entity % nw.component.scale or vec2(1, 1)
    local w, h = gfx.getWidth(), gfx.getHeight()

    gfx.translate(w / 2, h / 2)
    gfx.scale(scale.x, scale.y)
    gfx.translate(-pos.x, -pos.y)
end

function camera.sti_args(entity)
    local pos = entity % nw.component.position or vec2()

    return -pos.x, -pos.y
end

local function handle_wheelmoved(ecs_world, m)
    local et = ecs_world:get_component_table(component.camera)
    local scale = m.y > 0 and 1.1 or 0.9

    for id, _ in pairs(et) do
        local entity = ecs_world:entity(id)
        local s = entity:ensure(nw.component.scale, 1, 1)
        s.x = s.x * scale
        s.y = s.y * scale
    end
end

local function handle_mousemoved(ecs_world, x,  y, dx, dy)
    if not love.mouse.isDown(1) then return end

    local et = ecs_world:get_component_table(component.camera)

    for id, _ in pairs(et) do
        local entity = ecs_world:entity(id)
        local pos = entity:ensure(nw.component.position)
        local scale = entity:ensure(nw.component.scale, 1, 1)

        pos.x = pos.x - dx / scale.x
        pos.y = pos.y - dy / scale.y
    end
end

local function circular_slack(ecs_world, target, id)
    local target_pos = ecs_world:ensure(nw.component.position, target)
    local camera_pos = ecs_world:ensure(nw.component.position, id)
    local camera_opt = ecs_world:get(component.camera, id)

    local slack = camera_opt.slack or 0
    local diff = target_pos - camera_pos
    local l = diff:length()

    local l_adjust = math.max(0, l - slack)
    local adjust = diff * l_adjust / (l + 1e-10)
    local x = camera_pos.x + adjust.x
    local y = camera_pos.y + adjust.y

    ecs_world:set(nw.component.position, id, x, y)
end

local function box_slack(ecs_world, target, id)
    local target_pos = ecs_world:ensure(nw.component.position, target)
    local camera_pos = ecs_world:ensure(nw.component.position, id)
    local camera_opt = ecs_world:get(component.camera, id)

    local slack = camera_opt.slack or 0
    local diff = target_pos - camera_pos

    local sx, sy = math.abs(diff.x), math.abs(diff.y)
    local lx = math.clamp(sx - slack, 0, camera_opt.max_move)
    local ly = math.clamp(sy - slack, 0, camera_opt.max_move)
    local adjust_x = diff.x * lx / sx
    local adjust_y = diff.y * ly / sy
    local x = camera_pos.x + adjust_x
    local y = camera_pos.y + adjust_y

    ecs_world:set(nw.component.position, id, x, y)
end

local function handle_update(ecs_world, dt)
    local et = ecs_world:get_component_table(component.camera)

    Dictionary.keys(et):foreach(function(id)
        local target = ecs_world:get(component.target, id)
        if not target then return end
        box_slack(ecs_world, target, id)
    end)
end

function camera.draw_slack(entity)
    local camera_opt = entity:get(component.camera)
    local pos = entity:get(nw.component.position)

    if not camera_opt or not pos then return end

    gfx.setColor(1, 1, 1)

    local slack = camera_opt.slack or 0
    if camera_opt.slack_type == "circle" then
        gfx.circle("line", pos.x, pos.y, slack)
    else
        gfx.rectangle("line", pos.x - slack, pos.y - slack, slack * 2, slack * 2)
    end
end

function camera.system(ctx, ecs_world)
    local wheelmoved = ctx:listen("wheelmoved")
        :map(vec2)
        :collect()

    local mousemoved = ctx:listen("mousemoved")
        :collect()

    local update = ctx:listen("update")
        :collect()

    while ctx:is_alive() do
        wheelmoved
            :pop()
            :foreach(function(m)
                handle_wheelmoved(ecs_world, m)
            end)

        mousemoved
            :pop()
            :foreach(function(args)
                handle_mousemoved(ecs_world, unpack(args))
            end)

        update
            :pop()
            :foreach(function(dt)
                handle_update(ecs_world, dt)
            end)

        ctx:yield()
    end
end

return camera
