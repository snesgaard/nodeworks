local component = {}

---@param t number|nil
---@return number
function component.time(t) return t or 0 end


---@param duration number
---@param init_time number|nil
function component.timer(duration, init_time)
    return {
        duration = duration,
        time = init_time
    }
end

function component.die_on_timer_done() return true end

return component