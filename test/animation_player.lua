local rect = Node.create(function(self)
    self.pos = vec2(0, 0)
    self.__color = {1, 1, 1}
end)

function rect:color(r, g, b)
    if r then
        self.__color = {r, g, b}
        return self
    else
        return self.__color
    end
end

local player = Node.create(animation_player)

local pos = {vec2(100, 100), vec2(200, 200)}
local time = {0, 1}

local anime = player:animation("test")

anime
    :track("../pos", pos, time, {ease=ease.linear})
    :track(
        "../color",
        {{1, 1, 1}, {1, 0, 0}},
        {0, 0.5}
    )
    :duration(1)

rect:adopt(player)
player:play("test")

event:listen(player, "done", function() print("done") end)

function updater.animation_player(dt)
    player:update(dt)
    event:spin()
    --love.event.quit()
end

function drawer.animation_player(dt)
    gfx.setColor(unpack(rect:color()))
    gfx.rectangle("fill", rect.pos.x, rect.pos.y, 100, 100)
end
