local third =  {
    ---@module "knife.knife.test"
    test = require(... .. ".knife.knife.test"),
    ---@module "json.lua/json.lua"
    json = require(... .. "json.lua/json.lua")
}


return third