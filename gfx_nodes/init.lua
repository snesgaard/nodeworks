local BASE = ...

local nodes = {
    color = require(... .. ".color"),
    spatial = require(... .. ".spatial"),
}

local line_width_node = {}

function line_width_node.begin(self, w)
    self.w = w
end

line_width_node.memory = gfx.getLineWidth

function line_width_node:enter()
    gfx.setLineWidth(self.w)
end

function line_width_node:exit(w)
    gfx.setLineWidth(w)
end

local text_node = {}

function text_node:begin(text, align, valign, font, ...)
    self.font = font
    self.text = text
    self.align = align
    self.valign = valign
    self.args = {...}
end

text_node.memory = gfx.getFont

function text_node:enter()
    if not self.text then return end
    gfx.setFont(self.font)
    local font = self.font or gfx.getFont()
    local fh = font:getHeight()
    local space = spatialstack:peek()
    local x, y, w, h = space:unpack()
    if self.valign == "center" then
        y = y + (h - fh) / 2
    elseif self.valign == "bottom" then
        y = y + h - fh - 2
    end
    gfx.printf(self.text, x, y, w, self.align, unpack(self.args))
end

function text_node:exit(font)
    gfx.setFont(font)
end

local transform_node = {}

function transform_node:begin(x, y, r, sx, sy)
    self.x = x or 0
    self.y = y or 0
    self.r = r or 0
    self.sx = sx or 1
    self.sy = sy or 1
end

function transform_node:memory()
    gfx.push()
end

function transform_node:enter()
    gfx.translate(self.x, self.y)
    gfx.rotate(self.r)
    gfx.scale(self.sx, self.sy)
end

function transform_node:exit()
    gfx.pop()
end

local function draw_rect(mode)
    local spatial = spatialstack:peek()
    gfx.rectangle(mode, spatial:unpack())
end

local sprite = {}

function sprite:begin(...)
    local function get_args(a, ...)
        -- First case, we assume that data was given as arugments
        if type(a) == "userdata" then
            return a, ...
        -- Second we assume data was given as a frame
        elseif type(a) == "table" then
            local center = a.slices.origin or spatial()
            local offset = center:center() - a.offset
            return a.image, a.quad, offset
        end
    end

    self.image, self.quad, self.offset = get_args(...)
    self.offset = self.offset or vec2()
    self.scale = vec2(2, 2)
    self.pos = vec2()
end

function sprite:enter()
    if not self.image then return end
    local space = spatialstack:peek()
    local x, y = self.pos:unpack()
    x = x + space.x
    y = y + space.y
    local r = 0
    local sx, sy = self.scale:unpack()
    local ox, oy = self.offset:unpack()
    if self.quad then
        gfx.draw(self.image, self.quad, x, y, r, sx, sy, ox, oy)
    else
        gfx.draw(self.image, x, y, r, sx, sy, ox, oy)
    end
end

nodes.draw_rect = draw_rect
nodes.transform = transform_node
nodes.line_width = line_width_node
nodes.text = text_node
nodes.sprite = sprite

return nodes
