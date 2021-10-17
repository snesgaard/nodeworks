local rh = {}

require(... .. ".core")

rh.ease = require(... .. ".core.ease")

local BASE = ...

function rh.__index(t, k)
    return require(BASE .. "." .. k)
end

return setmetatable(rh, rh)
