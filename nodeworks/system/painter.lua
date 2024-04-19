---@module "nodeworks.component"
local component = require "nodeworks.component"
---@module "nodeworks.ecs.stack"
local stack = require "nodeworks.ecs.stack"
---@module "nodeworks.core.dict"
local dict = require "nodeworks.core.dict"
---@module "nodeworks.core.misc"
local misc = require "nodeworks.core.misc"

local drawable = {}

local painter = {
    drawable = drawable
}

---@param a Id
---@param b Id
---@return boolean b_greater_than_a
function painter.compare_entities(a, b)
    local layer_a = stack.get_or_default(component.layer, a)
    local layer_b = stack.get_or_default(component.layer, b)

    if layer_a ~= layer_b then return layer_a < layer_b end

    local pos_a = stack.get_or_default(component.position, a, 0, 0)
    local pos_b = stack.get_or_default(component.position, b, 0, 0)

    local dx = pos_b.x - pos_a.x 
    local dy = pos_b.y - pos_a.y

    if 1 < math.abs(dx) then return dx > 0 end

    return dy > 0
end

---@param id Id
---@param drawable_type string
function painter.draw_entity(id, drawable_type)
    local draw_func = drawable[drawable_type]
    if draw_func == nil then
        misc.print("Unknown drawable type: ", drawable_type)
    else
        return draw_func(id)
    end
end

function painter.draw()
    local drawable_table = stack.get_table(component.drawable)
    local drawable_ids = dict.keys(drawable_table)
    table.sort(drawable_ids, painter.compare_entities)

    for _, id in ipairs(drawable_ids) do
        local drawable_type = drawable_table[id] or "__unknown__"
        love.graphics.push("all")
        painter.draw_entity(id, drawable_type)
        love.graphics.pop()
    end
end

return painter