local function create_frame(x, y, r, sx, sy)
    x = x or 0
    y = y or 0
    r = r or 0
    sx = sx or 1
    sy = sy or sx
    return {x = x, y = y, r = r, sx = sx, sy = sy or sx}
end

local id_frame = create_frame()

local transform = {}
transform.__index = transform

function transform:set(frame, ...)
    self.__frames[frame] = create_frame(...)
end

function transform:draw(frame, f, ...)
    local parts = self.split(frame)
    gfx.push()

    gfx.scale(-1, 1)
    for i, p in ipairs(parts) do
        local f = self.__frames[p] or id_frame
        gfx.translate(f.x, f.y)
        gfx.rotate(f.r)
        gfx.scale(f.sx, f.sy)
    end


    f(...)

    gfx.pop()
end

function transform:get(path, point)

end

function transform.split(path)
    return string.split(path, '/')
end

return function()
    local this = {}

    this.__frames = {}
    return setmetatable(this, transform)
end
