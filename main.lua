require "init"

local sprite_draw_system = ecs.system(components.sprite)

function sprite_draw_system:draw()
    gfx.setColor(1, 1, 1)
    for _, entity in ipairs(self.pool) do
        local sprite = entity[components.sprite]
        local image = sprite[components.image]
        local args = sprite[components.draw_args]

        gfx.push()

        local position = entity[components.position] or components.position()
        gfx.translate(position:unpack())

        local slices = sprite[components.slices]
        local body_key = sprite[components.body_slice]
        local body_slice = slices[body_key] or spatial()
        local c = body_slice:centerbottom()
        local ox, oy = args.ox + c.x, args.oy + c.y
        local sx = sprite[components.mirror] and -1 or 1

        if image.image and image.quad then
            gfx.draw(
                image.image, image.quad,
                args.x, args.y, args.r, sx * args.sx, args.sy, ox, oy
            )
        elseif image.image then
            gfx.draw(
                image.image,
                args.x, args.y, args.r, sx * args.sx, args.sy, ox, oy
            )
        end

        gfx.pop()
    end
end

local root_motion_system = ecs.system(components.position)

function root_motion_system:on_next_frame(entity, prev_frame, next_frame)
    if not self.pool[entity] then return end
    print("next_frame")
end

function root_motion_system:on_animation_ended(entity)
    print("no more!")
end

function draw_scene(self)
    self.canvas = self.canvas or gfx.newCanvas(gfx.getWidth(), gfx.getHeight())
    gfx.setCanvas(self.canvas)

    gfx.clear(0, 0, 0, 0)
    gfx.scale(2, 2)
    world("draw")
    
    return self.canvas
end

function add_scene(self, ...)
    self.canvas = self.canvas or gfx.newCanvas(gfx.getWidth(), gfx.getHeight())
    gfx.setCanvas(self.canvas)

    local buffers = {...}
    gfx.clear(0, 0, 0, 1)
    gfx.setBlendMode("add")
    for _, b in ipairs(buffers) do
        gfx.draw(b, 0, 0)
    end

    return self.canvas
end

function love.load()
    world = ecs.world(
        systems.animation,
        root_motion_system,
        systems.particles,
        systems.hitbox_sprite,
        systems.motion,
        systems.collision,
        systems.hitbox,
        sprite_draw_system
    )

    systems.collision.show()

    local atlas = get_atlas("build/characters")
    local frame = atlas:get_frame("wizard_movement/idle")
    bump_world = bump.newWorld()

    test_entity = ecs.entity(world)
        :add(components.sprite)
        :add(components.position, 200, 150)
        :add(components.velocity, 20, 0)
        :add(components.animation_map, atlas, {
            idle="wizard_movement/idle", run="wizard_movement/run",
            hot="test"
        })
        :add(components.animation_state)
        :add(components.body, -10, -20, 20, 20)
        :add(components.bump_world, bump_world)
        :add(components.body_slice)
        :add(components.hitbox_collection, {yo=spatial(0, 0, 100, 100)})

    test_entity2 = ecs.entity(world)
        :add(components.body, 300, 0, 50, 4000)
        :add(components.position)
        :add(components.bump_world, bump_world)

    test_entity3 = ecs.entity(world)
        :add(components.position, 275, 200)
        :add(components.body, 0, 0, 50, 50)
        :add(components.bump_world, bump_world)

    --test_entity[components.sprite]:update(components.mirror, true)

    draw_scene_node = render_graph(draw_scene)
    add_node = render_graph(add_scene):link(draw_scene_node, draw_scene_node)

    systems.animation.play(test_entity, "run", true)
end

function love.keypressed(key, scancode, isrepeat)
    event("keypressed", key)

    if key == "d" then test_entity:remove() end

    if key == "escape" then love.event.quit() end

    if key == "space" then
        local sprite = test_entity[components.sprite]
        sprite:map(components.mirror, function(m) return not m end)
    end
end

function love.update(dt)
    world("update", dt)
    event:spin()
end

function love.draw()
    --gfx.scale(2, 2)
    --world("draw")
     :draw()
    --gfx.draw(frame.image, frame.quad, 100, 100)
end
