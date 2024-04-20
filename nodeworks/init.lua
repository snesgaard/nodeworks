return {
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
    ---@module "component"
    component = require(... .. ".component"),
    ---@module "event_type"
    event_type = require(... .. ".event_type"),
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
        camera = require (... .. ".system.camera")
    }
}
