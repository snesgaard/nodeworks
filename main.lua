function love.load(args)
    local example = unpack(args)

    if not example then
        require("test")
        print("ALL TEST PASSED")
        love.event.quit()
        return
    end

    local old_load = love.load
    require(example:gsub("%.lua", ""))
    if love.load ~= old_load then love.load() end
end
