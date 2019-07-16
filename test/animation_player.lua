local rect = Node.create(function(self)
    self.pos = vec2(0, 0)
    self.color = color(1, 1, 1)
end)

local time = {0, 1}
local value = {color(1, 1, 1), color(1, 0, 0)}

local time_f = {0.5}
local value_f = {{"/animation/ready", 1}}

player = Node.create(animation_player)
local anime = player:animation("test")

function add(c, a, b)
    return c + a - (b or 0)
end

anime
    :track(
        "../pos", {0, 2}, {vec2(0, 0), vec2(200, 200)},
        {ease=ease.linear, agg=add}
    )
    :track("../color", time, value, {ease=ease.linear})
    :track(unpacked(event), time_f, value_f, {call=true})
    :duration(2.0)

player:play("test", true)

rect:adopt(player)

time = 0

event:listen("/animation/ready", print, "it is called")

function updater.animation_player(dt)
    player:update(dt)
    event:spin()

    time = time + dt
    --love.event.quit()
end

function drawer.animation_player(dt)
    gfx.setColor(unpack(rect.color))
    gfx.rectangle("fill", rect.pos.x, rect.pos.y, 100, 100)

    local s = spatial(gfx.getWidth(), 0, 100, 100):move(-100, 0)
    gfx.setColor(0.1, 0.2, 1, 0.2)
    gfx.rectangle("fill", s:unpack())
    gfx.setColor(1, 1, 1)
    gfx.printf(string.format("%0.2fs", time), s.x, s.y, s.w)

end
