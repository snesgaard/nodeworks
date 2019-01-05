local post_process = {}

function post_process:create()
    local w, h = gfx.getWidth(), gfx.getHeight()
    self.buffers = list(gfx.newCanvas(w, h), gfx.newCanvas(w, h))
end

function post_process:front()
    return self.buffers:head()
end

function post_process:back()
    return self.buffers:tail()
end

function post_process:swap()
    self.buffers = self.buffers:reverse()
end

function post_process:draw()
    for _, node in ipairs(self.__node_order) do
        gfx.setCanvas(self:back())
        gfx.clear(0, 0, 0, 0)
        gfx.setColor(1, 1, 1)

        node:draw(
            self:front(), node.__transform.pos.x, node.__transform.pos.y
        )

        self:swap()
    end

    gfx.setCanvas()
    gfx.setShader()
    gfx.setColor(1, 1, 1)
    gfx.draw(self:front(), 0, 0)
end

return post_process
