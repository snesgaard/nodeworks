local nw = require "nodeworks"
local T = nw.third.knife.test
local Reducer = nw.ecs.reducer
local epoch = Reducer.epoch

local component = {}

function component.value(v) return v or 0 end

local function add(a, b) return a + b end
