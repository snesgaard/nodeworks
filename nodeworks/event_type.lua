local event_type = {}

---@param dt number
---@return number
function event_type.update(dt) return dt or 0 end

---@param ax number
---@param ay number
---@param collision CollisionInfo[]
function event_type.move(ax, ay, collision)
    return {
        ax = ax,
        ay = ay,
        collision = collision
    }
end

return event_type