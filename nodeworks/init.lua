local nw = {
    ---@module "nodeworks.core.video"
    video = require(... .. ".core.video"),
    ---@module "vec2"
    vec2 = require(... .. ".core.vec2"),
    ---@module "spatial"
    spatial = require(... .. ".core.spatial"),
    ---@module "list"
    list = require(... .. ".core.list"),
    ---@module "atlas"
    atlas = require(... .. ".core.atlas"),
    ---@module "misc"
    misc = require(... .. ".core.misc"),
    ---@module "dict"
    dict = require(... .. ".core.dict"),
    ---@module "nodeworks.component"
    component = require(... .. ".component"),
    ---@module "event_type"
    event_type = require(... .. ".event_type"),
    ---@module "ai"
    ai = require (... .. ".core.ai"),
    ecs = {
        ---@module "id"
        id = require(... .. ".ecs.id"),
        ---@module "world"
        world = require(... .. ".ecs.world"),
        ---@module "stack"
        stack = require(... .. ".ecs.stack")
    },
    system = {
        ---@module "nodeworks.system.event"
        event = require(... .. ".system.event"),
        ---@module "nodeworks.system.time"
        time = require(... .. ".system.time"),
        ---@module "nodeworks.system.collision"
        collision = require(... .. ".system.collision"),
        ---@module "nodeworks.system.tf"
        tf = require(... .. ".system.tf"),
        ---@module "nodeworks.system.sprite_animation",
        sprite_animation = require (... .. ".system.sprite_animation"),
        ---@module "nodeworks.system.follow"
        follow = require (... .. ".system.follow"),
        ---@module "nodeworks.system.painter"
        painter = require (... .. ".system.painter"),
        ---@module "nodeworks.system.map"
        map = require (... .. ".system.map"),
        ---@module "nodeworks.system.camera"
        camera = require (... .. ".system.camera"),
        ---@module "nodeworks.system.resource"
        resource = require (... .. ".system.resource"),
        ---@module "nodeworks.system.behavior"
        behavior = require (... .. ".system.behavior")
    }
}

nw.stack = nw.ecs.stack
nw.event = nw.system.event

function nw.shortcuts()
    stack = nw.ecs.stack
    event = nw.system.event
    event_type = nw.event_type
end

function nw.user_spin()
end

function nw.spin()
    while nw.system.event.swap() do
        nw.system.time.spin()
        nw.system.sprite_animation.spin()
        nw.system.follow.spin()
        nw.system.map.spin()
        nw.system.behavior.spin()
        nw.user_spin()
    end
end

nw.enable_collision_debug_draw = false

function nw.configure()
    ---@param dt number
    function love.update(dt)
        nw.system.event.emit(nw.event_type.update, dt)
        nw.spin()
    end

    function love.draw()
        for camera_id, _ in nw.ecs.stack.view_table(nw.component.is_camera) do
            nw.system.painter.draw(camera_id)

            if nw.enable_collision_debug_draw then
                love.graphics.push()
                local camera_pos, camera_scale = nw.system.camera.get_transform(camera_id)
                nw.system.camera.push_transform(camera_pos, camera_scale, nw.vec2(1, 1))
                nw.system.collision.draw()
                love.graphics.pop()
            end
        end
    end

    ---@param key string
    ---@param is_repeat boolean
    function love.keypressed(key, _, is_repeat)
        nw.system.event.emit(nw.event_type.keypressed, key, is_repeat)
    end

    ---@param key string
    function love.keyreleased(key)
        nw.system.event.emit(nw.event_type.keyreleased, key)
    end

    ---@param joystick love.Joystick
    ---@param button string
    function love.gamepadpressed(joystick, button)
        nw.system.event.emit(nw.event_type.gamepadpressed, joystick, button)
    end

    ---@param joystick love.Joystick
    ---@param button string
    function love.gamepadreleased(joystick, button)
        nw.system.event.emit(nw.event_type.gamepadreleased, joystick, button)
    end

    ---@param joystick love.Joystick
    ---@param axis string
    ---@param value number
    function love.gamepadaxis(joystick, axis, value)
        nw.system.event.emit(nw.event_type.gamepadaxis, joystick, axis, value)
    end
end

return nw