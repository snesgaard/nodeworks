local translate = {}
local rotate = {}
local scale = {}
local color = {}
local rectangle = {}
local blend = {}
local canvas = {}

function translate:begin(x, y)
    self.x = x
    self.y = y
end

function translate:enter()
    gfx.push()
    gfx.translate(self.x, self.y)
end

function translate:exit()
    gfx.pop()
end

function scale:enter()
    gfx.scale(self.x, self.y)
end

function scale:exit()
    gfx.pop()
end

function rotate:begin(angle)
    self.angle = angle
end

function rotate:enter()
    gfx.push()
    gfx.rotate(self.angle)
end

function rotate:exit()
    gfx.pop()
end

function color:begin(...)
    self.color = {...}
end

function color:enter()
    gfx.setColor(unpack(self.color))
end

function color:memory()
    return {gfx.getColor()}
end

function color:exit(prev_color)
    gfx.setColor(unpack(prev_color))
end

function rectangle:begin(fill, x, y, w, h)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    self.fill = fill
end

function rectangle:enter()
    gfx.rectangle(self.fill, self.x, self.y, self.w, self.h)
end

function blend:enter()
    gfx.setBlendMode(self.mode)
end

function blend:memory()
    return gfx.getBlendMode()
end

function blend:exit(prev)
    gfx.setBlendMode(prev)
end

function canvas:enter()
    gfx.setCanvas(self.canvas)
end

function canvas:memory()
    return gfx.getCanvas()
end

function canvas:exit(prev)
    gfx.setCanvas(prev)
end

return {
    translate = translate, rotate = rotate, scale = scale,
    color = color, rectangle = rectangle, blend = blend,
    canvas = canvas
}
