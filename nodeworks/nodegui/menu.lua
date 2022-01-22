local nw = require "nodeworks"

local menu = {}

function menu.on_enter(core)
    core.layout:expand(-10, -10):push()
end


function menu.on_exit()
    -- Compute final shape
end

function menu.on_child(core, id, child_id)
    local state = core:state(id)
    local child_count = #core.graph:children(id)

    if child_count > 1 then
        core.layout
            :down()
            :move(0, child_count and 10 or 0)
    end

    if state.item == child_count and state.select then
        core.focus:request(id, child_id)
    end
end

local function to_border(shape)
    return shape.x, shape.y, shape.x + shape.w, shape.y + shape.h
end

local function merge_border(shape, lx, ly, ux, uy)
    local slx, sly, sux, suy = to_border(shape)
    return math.min(slx, lx), math.min(sly, ly), math.max(sux, ux), math.max(suy, uy)
end

function menu.on_exit(core, id)
    local children = core.graph:children(id)

    if #children == 0 then return end

    local lx, ly, ux, uy = math.huge, math.huge, -math.huge, -math.huge

    for _, child_id in ipairs(children) do
        local s = core:shape(child_id)
        lx, ly, ux, uy = merge_border(s, lx, ly, ux, uy)
    end

    local shape = spatial(lx, ly, ux - lx, uy - ly):expand(10, 10)

    core.layer:rectangle(shape)
        :set(nw.component.draw_mode, "fill")
end

return menu
