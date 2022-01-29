local nw = require "nodeworks"

local function menu_state_component()
    return {select = false}
end

local function build_layout(core, id, items)
    local style = core.style or {}
    local pos = core:state(id):ensure(nw.component.position)
    local w, h = (style.menu_item_size or vec2(150, 20)):unpack()
    local outer_margin = style.outer_menu_margin or vec2(10, 10)
    local item_margin = style.item_margin or 10

    local init_shape = spatial(pos.x, pos.y, w, h)

    local item_shapes = {}

    for _, _ in ipairs(items) do
        table.insert(item_shapes, init_shape)
        init_shape = init_shape:down():move(0, item_margin)
    end

    local menu_shape = Spatial.join(unpack(item_shapes))
        :expand(outer_margin.x, outer_margin.y)

    return {menu_shape=menu_shape, item_shapes=item_shapes}
end

local function render_shape(shape)
    return nw.ecs.entity()
        :set(nw.component.drawable, "rectangle")
        :set(nw.component.draw_mode, "fill")
        :set(nw.component.rectangle, shape)
end

local function render_main_shape(shape, style)
    local color = style.menu_background_color or {0.5, 0.5, 0.5}
    return render_shape(shape):set(nw.component.color, color)
end

local function button_color(selected, style)
    if selected then
        return style.menu_select_color or {1, 1, 1}
    else
        return style.menu_item_color or {0.8, 0.8, 0.8}
    end
end

local function render_button_shape(shape, selected, style)
    local color = button_color(selected, style)
    return render_shape(shape):set(nw.component.color, color)
end

local function render_outline(shape, style)
    local select_margin = style.menu_select_margin or 6
    local color = style.menu_select_color or {1, 1, 1}
    return render_shape(shape:expand(select_margin, select_margin))
        :set(nw.component.color, color)
end

local function render_text(text, shape, style)
    return nw.ecs.entity()
        :set(nw.component.drawable, "text")
        :set(nw.component.rectangle, shape)
        :set(nw.component.color, {0, 0, 0})
        :set(nw.component.text, text)
        :set(nw.component.align, "center")
end

local function render_layout(core, id, items, layout, style)
    local style = style or {}

    local pool = core:layer_pool()
    local state = core:state(id):ensure(menu_state_component)

    pool:add(render_main_shape(layout.menu_shape, style))

    for index, item in ipairs(items) do
        local shape = layout.item_shapes[index]
        local howered = index == state.index
        local selected = howered and state.select
        if howered and not selected then
            pool:add(render_outline(shape, style))
        end
        pool:add(render_button_shape(shape, selected, style))
        pool:add(render_text(item, shape, style))
    end
end

local function menu_step(index, up, down, count)
    local step = 0
    if up then step = step - 1 end
    if down then step = step + 1 end

    if step == 0 then return index end

    if not index then return step > 0 and 1 or count end

    if step > 0 then
        return count <= index and 1 or (index + 1)
    else
        return index <= 1 and count or (index - 1)
    end
end

local function update_state(core, id, items)
    local state = core:state(id):ensure(menu_state_component)
    local input = core.world:singleton()

    if state.select then
        local cancel = nw.system.input_buffer.is_pressed(input, "backspace") ~= nil
        if cancel then state.select = false end
    else
        local confirm = nw.system.input_buffer.is_pressed(input, "space") ~= nil
        if confirm then state.select = true end
    end

    if not state.select then
        local up = nw.system.input_buffer.is_pressed(input, "up") ~= nil
        local down = nw.system.input_buffer.is_pressed(input, "down") ~= nil
        state.index = menu_step(state.index, up, down, #items)
    end
end

local function handle_return(core, id, items, ...)
    update_state(core, id, items)
    return ...
end

return function(core, id, items, cb, ...)
    local layout = build_layout(core, id, items, style)
    render_layout(core, id, items, layout)

    local state = core:state(id):ensure(menu_state_component)

    if state.select and state.index and type(cb) == "function" then
        local item = items[state.index]
        return handle_return(core, id, items, cb(core, item, ...))
    end

    return handle_return(core, id, items)
end
