require "."

local componentA = function()  return "A" end
local componentB = function()  return "B" end
local componentC = function()  return "C" end


local systemA = ecs.system(componentA, componentB)

function systemA.on_entity_added()
    print("add A")
end

function systemA.on_entity_removed()
    print("remove A")
end

local systemB = ecs.system.from_function(function(entity)
    return {
        everything = true,
        picky = entity:has(componentA, componentC)
    }
end)

function systemB:on_entity_added(entity, pool)
    print("yes", pool)
end

function systemB:on_entity_removed(entity, pool)
    print("removed", pool)
end

function love.load()
    world = ecs.world(
        systemA,
        systemB
    )

    ecs.entity(world)
        :add(componentA)
        :add(componentB)
        :remove(componentB)
        :add(componentB)
        :add(componentC)
        :destroy()

end

function love.keypressed(key, scancode, isrepeat)
    world("keypressed", key)
    if key == "escape" then love.event.quit() end
end

function love.update(dt)
    world("update", dt)
end

function love.draw()
    world("draw")
end
