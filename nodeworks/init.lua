return {
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
        event = require(... .. ".system.event")
    }
}
