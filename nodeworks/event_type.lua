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

return event_type