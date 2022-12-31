local rh = {}

require(... .. ".core")

rh.just = Result.just
rh.empty = Result.empty

rh.ease = require(... .. ".core.ease")
rh.Task = require(... .. ".core.task")
rh.task = rh.Task.create

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

return setmetatable(rh, rh)
