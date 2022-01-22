local nw = require "nodeworks"

local function index_component(index) return index end
local function select_component(state) return state or false end

local function render_menu(entity, layer, items)
    local shape = spatial(0, 0, 150, 50)
    local margin = 10
    local pool = layer:ensure(nw.component.layer_pool)
    local item_index = entity[index_component]
    local select = entity[select_component]

    local shapes = list()

    for _, _ in ipairs(items) do
        table.insert(shapes, shape)

        shape = shape:down():move(0, margin)
    end

    local frame_shape = Spatial.join(shapes:unpack()):expand(margin)

    local function render_shape(shape)
        return nw.ecs.entity()
            :set(nw.component.drawable, "rectangle")
            :set(nw.component.rectangle, shape)
            :set(nw.component.draw_mode, "fill")
    end

    pool:add(render_shape(frame_shape):set(nw.component.color, 1, 0, 1))

    if item_index then
        local shape = shapes[item_index]
        pool:add(render_shape(shape:expand(10, 10)):set(nw.component.color, 1, 1, 0))
    end

    for index, item in ipairs(items) do
        local shape = shapes[index]
        local e = render_shape(shape)
        if index == item_index and select then
            e:set(nw.component.color, 1, 1, 0)
        end
        pool:add(e)
    end
end

local function menu_step(index, up, down, count)
    local step = 0
    if up then step = step - 1 end
    if down then step = step + 1 end

    if step == 0 then return index end

    if not index then return step > 0 and 1 or count end

    if step > 0 then
        return index == count and 1 or (index + 1)
    else
        return index == 1 and count or (index - 1)
    end
end

local function menu(world, entity, layer, items)
    local index = entity[index_component]
    local select = entity:ensure(select_component, false)

    local up = nw.system.input_buffer.is_pressed(world:singleton(), "up") ~= nil
    local down = nw.system.input_buffer.is_pressed(world:singleton(), "down") ~= nil

    if select then
        if nw.system.input_buffer.is_pressed(world:singleton(), "cancel") then
            select = false
        end
    else
        if nw.system.input_buffer.is_pressed(world:singleton(), "confirm") then
            select = index ~= nil
        end
    end

    if not select then index = menu_step(index, up, down, #items) end

    entity
        :set(index_component, index)
        :set(select_component, select)

    render_menu(entity, layer, items)

    return index, select
end


function love.load()
    world = nw.ecs.world{nw.system.input_buffer, nw.system.render}

    gui_layer = world:entity()
        :set(nw.component.layer_type, "entitygroup")

    menu_entity = world:entity()
end

function love.update(dt)
    local items = {"foo", "bar", "baz"}
    gui_layer:set(nw.component.layer_pool)
    menu(world, menu_entity, gui_layer, items)
    world("update", dt)
end

function love.draw()
    world("draw")
end

function love.keypressed(key, scancode, isrepeat)
    world("input_pressed", key)
    if key == "escape" then love.event.quit() end
end
