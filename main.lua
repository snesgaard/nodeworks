require "init"

function subkeys(behave)
    print("subkey", event:wait("keypressed"))
    return subkeys(behave)
end


function love.load()

    main_thread = behavior(function(behave)

        behave(subkeys)

        while true do
            local key = event:wait("keypressed")
            if key == "a" then
                behave:remove(subkeys)
            elseif key == "b" then
                behave(subkeys)
            end
        end

    end)

end

function love.keypressed(key, scancode, isrepeat)
    event("keypressed", key)
end

function love.update(dt)
    event:spin()
end
