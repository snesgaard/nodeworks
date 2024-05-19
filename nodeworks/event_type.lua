local event_type = {}

---@param dt number
---@return number
function event_type.update(dt) return dt or 0 end

---@param ax number
---@param ay number
---@param collision CollisionInfo[]
function event_type.move(id, ax, ay, collision)
    return {
        id = id,
        ax = ax,
        ay = ay,
        collision = collision
    }
end

---@param mirror boolean|nil
function event_type.flip_to(id, mirror)
    return {
        id = id,
        mirror = mirror
    }
end

---@param key string
---@param is_repeat boolean
function event_type.keypressed(key, is_repeat)
    return {
        key = key,
        is_repeat = is_repeat
    }
end

---@param key string
function event_type.keyreleased(key)
    return key
end

---@param joystick love.Joystick
---@param button string
function event_type.gamepadpressed(joystick, button)
    return {
        joystick = joystick,
        button = button
    }
end

---@param joystick love.Joystick
---@param button string
function event_type.gamepadreleased(joystick, button)
    return {
        joystick = joystick,
        button = button
    }
end

---@param joystick love.Joystick
---@param axis string
---@param value number
function event_type.gamepadaxis(joystick, axis, value)
    return {
        joystick = joystick,
        axis = axis,
        value = value
    }
end

---@param x number
---@param y number
---@param button integer
function event_type.mousepressed(x, y, button)
    return {
        x = x,
        y = y,
        button = button
    }
end

---@param x number
---@param y number
---@param button integer
function event_type.mousereleased(x, y, button)
    return {
        x = x,
        y = y,
        button = button
    }
end

---@param x number
---@param y number
---@param dx number
---@param dy number
function event_type.mousemoved(x, y, dx, dy)
    return {
        x = x,
        y = y,
        dx = dx,
        dy = dy
    }
end

---@param id Id
function event_type.entity_mousepressed(id, button)
    return {
        id = id,
        button = button
    }
end

---@param id Id
function event_type.entity_mousereleased(id, button)
    return {
        id = id,
        button = button
    }
end

function event_type.is_mouse_hovering() return true end

return event_type