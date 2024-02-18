local rh = {}

require(... .. ".core")

rh.just = Result.just
rh.empty = Result.empty

rh.ease = require(... .. ".core.ease")
rh.Task = require(... .. ".core.task")
rh.task = rh.Task.create
rh.animation = require(... .. ".core.animation")
rh.compute = require(... .. ".core.computation")
rh.particles = particles

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

rh.third = require(... .. ".third")

return setmetatable(rh, rh)
