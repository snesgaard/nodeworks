local transform = {}
local translate = {}
local rotate = {}
local scale = {}
local color = {}
local rectangle = {}
local blend = {}
local canvas = {}
local blur = {}
local subgraph = {}
local texture = {}
local blur = {}

function transform:begin(x, y, r, sx, sy)
    self.x = x or 0
    self.y = y or 0
    self.r = r or 0
    self.sx = sx or 1
    self.sy = sy or 1
end

function transform:enter()
    gfx.push()
    gfx.translate(self.x, self.y)
    gfx.rotate(self.r)
    gfx.scale(self.sx, self.sy)
end

function transform:translate(x, y)
    self.x, self.y = x, y
    return self
end

function transform.exit()
    gfx.pop()
end

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

function color:begin(style, ...)
    self.style = style or "replace"
    self.color = {...}
end

function color:enter()
    if self.style == "replace" then
        gfx.setColor(unpack(self.color))
    elseif self.style == "blend" then
        local prev = {gfx.getColor()}
        local next = {}
        for i = 1, 4 do
            next[i] = (prev[i] or 1) * (self.color[i] or 1)
        end
        gfx.setColor(unpack(next))
    end
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

function canvas:begin(w, h)
    self.canvas = gfx.newCanvas(w, h)
end

function canvas:enter()
    gfx.setCanvas(self.canvas)
    gfx.clear(0, 0, 0, 0)
end

function canvas:memory()
    return gfx.getCanvas()
end

function canvas:exit(prev)
    gfx.setCanvas(prev)
end

function canvas:clear()
    -- Figure out how to clear canvas when internets
    --self.canvas:clearColor()
end

function texture:begin(...)
    local function get_args(texture, quad, ...)
        if type(quad) == "number" then
            return texture, nil, quad, ...
        else
            return texture, quad, ...
        end
    end

    self.texture, self.quad, self.ox, self.oy = get_args(...)
end

function texture:drawargs()
    local x, y, r, sx, sy = 0, 0, 0, 1, 1
    return x, y, r, sx, sy, self.ox or 0, self.oy or 0
end

function texture:enter()
    if not self.texture then return end
    if self.quad then
        gfx.draw(self.texture, self.quad, self:drawargs())
    else
        gfx.draw(self.texture, self:drawargs())
    end
end

function blur:begin(sigma, canvas)
    self.blur = moon(moon.effects.gaussianblur)
    self.blur.sigma = sigma
    self.canvas = canvas
end

function blur:enter()
    self.blur(function()
        gfx.draw(self.canvas.canvas, 0, 0)
    end)
end

return {
    translate = translate, rotate = rotate, scale = scale,
    color = color, rectangle = rectangle, blend = blend,
    canvas = canvas, transform = transform, texture = texture,
    blur = blur
}
