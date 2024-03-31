local third =  {
    ---@module "knife.knife.test"
    test = require(... .. ".knife.knife.test"),
    ---@module "json.json"
    json = require(... .. ".json.json")
}

return third