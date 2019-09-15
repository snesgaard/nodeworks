require "init"

function assert(bool, msg)
    if not bool then
        error(msg or "Fail")
    end
end

function is_empty(table)
    for key, val in pairs(table) do
        return false
    end
    return true
end

local _old_resume = coroutine.resume

function coroutine.resume(...)
    local states = {_old_resume(...)}
    if not states[1] then
        error(states[2])
    end
    return unpack(states)
end

updater = {}

drawer = {}

function love.load()
    require "test.event_server"
    --require "test.node"
    --require "test.animation_player"
    --love.event.quit()
end

function love.update(dt)
    for _, f in pairs(updater) do
        f(dt)
    end
end

function love.draw()
    for _, f in pairs(drawer) do
        f()
    end
end
