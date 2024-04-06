local third =  {
    ---@module "knife.knife.test"
    test = require(... .. ".knife.knife.test"),
    ---@module "json.json"
    json = require(... .. ".json.json"),
    ---@module "bump"
    bump = require(... .. ".bump.bump"),
    ---@module "bump_debug"
    bump_debug = require(... .. ".bump_debug")
}

return third