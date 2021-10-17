local nw = require "."
require("test")
print("ALL TEST PASSED")

function love.load()
    love.event.quit()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
end

function love.draw()
end
