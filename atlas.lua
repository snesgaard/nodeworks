local List       = require "list"
local Dictionary = require "dictionary"
local Event      = require "event"
local Spatial    = require "spatial"
local json       = require "modules/json"

local Frame = {}
Frame.__index = Frame

function Frame.create(quad, ox, oy, t)
    local this = {quad = quad, ox = ox, oy = oy, time = t, hitbox = {}}
    return setmetatable(this, Frame)
end

local Sprite = {}
Sprite.__index = Sprite

function Sprite:__tostring()
    return string.format("Sprite <%s>", self.atlas.path)
end

function Sprite.create(atlas, aliases)
    local this = {
        aliases = aliases,
        atlas = atlas,
        animation = "none",
        frames = nil,
        time = 0,
        f = 1,
        color = {255, 255, 255, 255},
        loop = "repeat",
        spatial = Spatial.create(),
        on_completed = Event.create(),
        on_frame_changed = Event.create(),
        on_animation_changed = Event.create()
    }
    return setmetatable(this, Sprite)
end

function Sprite:set_animation(name)
    if self.aliases then
        name = self.aliases[name]
    end
    local frames = self.atlas:get_animation(name)
    if not frames then
        log.warn("Animation <%s> is not defined", name)
    end
    self.animation = name
    self.frames = frames
    self.time = frames:head().time
    self.f = 1
    self.on_animation_changed(name)
    return self
end

function Sprite:set_loop(loop)
    self.loop = loop
    return self
end

function Sprite.set_color(r, g, b, a)
    self.color = {r, g, b, a}
    return self
end

function Sprite:set_frame(f)
    self.f = f
    if self.frames:size() < self.f then
        -- Throw end of animation event
        self.on_completed()
        if self.loop == "once" then
            return
        elseif self.loop == "repeat" then
            self.f = 1
        end
    else
        self.on_frame_changed(self.f)
        -- Throw end of frame
    end
    -- Throw animation hitbox info here
    return self
end

function Sprite:next_frame()
    return self:set_frame(self.f + 1)
end

function Sprite:set_time(time)
    self.time = time
    return self
end

function Sprite:set_origin(origin)
    self.origin = origin
    return self
end

function Sprite:refresh_time()
    local frame = self.frames[self.f]
    return self:set_time(self.time + frame.time)
end

function Sprite:update(dt)
    self.time = self.time - dt
    if self.time < 0 then
        self:next_frame()
            :refresh_time()
        return self:update(0)
    end
    return self
end

function Sprite:draw(x, y, r, sx, sy)
    gfx.setColor(unpack(self.color))
    x = x + self.spatial.x
    y = y + self.spatial.y
    self.atlas:draw(self.frames[self.f], self.origin, x, y, r, sx, sy)
end

local Atlas = {}
Atlas.__index = Atlas

function Atlas:__tostring()
    return string.format("Atlas <%s>", self.path)
end

local function read_file(path)
    local info = love.filesystem.getInfo(path .. '.lua')
    return info and require(path) or {}
end

local function read_json(positional, path)
    local data, err = love.filesystem.newFileData(path)
    if data:getExtension() == 'json' then
        return json.decode(love.filesystem.read(path))
    else
        return {
            frames = {
                {
                    frame = {x = -1, y = -1, w = positional.w + 2, h = positional.h + 2},
                    duration = 1000, spriteSourceSize = {x = 0, y = 0}
                }
            },
            meta = {slices = {}, frameTags = {}}
        }
    end
end

function Atlas.create(path)
    local sheet = gfx.newImage(path .. "/atlas.png")
    local index = require (path   .. "/index")

    local atlas_hitbox_mask = read_file(path .. "/hitbox")

    local this = {
        frames = Dictionary.create(),
        tags   = Dictionary.create(),
        slices = Dictionary.create(),
        sheet  = sheet,
        normal = normal,
        path = path,
    }

    local function calculate_border(lx, ux) return lx + ux end

    local dim = {sheet:getDimensions()}
    for name, positional in pairs(index) do
        local frame_hitbox_mask = atlas_hitbox_mask[name] or {}

        local data_path = path .. '/' .. positional.data
        local data = read_json(positional, data_path )
        local frames = List.create()
        for _, f in ipairs(data.frames) do
            local x = f.frame.x + positional.x + 1
            local y = f.frame.y + positional.y + 1
            local w, h = f.frame.w - 2, f.frame.h - 2
            local quad = gfx.newQuad(x, y, w, h, unpack(dim))
            local dt = f.duration / 1000.0
            local ox, oy = f.spriteSourceSize.x, f.spriteSourceSize.y
            frames[#frames + 1] = Frame.create(quad, ox, oy, dt)
        end
        -- Update slices with a central bound

        for _, slice in pairs(data.meta.slices) do
            local hitboxes = List.create()
            for _, k in ipairs(slice.keys) do
                k.bounds.cx = k.bounds.x + k.bounds.w * 0.5 - 0.5
                k.bounds.cy = k.bounds.y + k.bounds.h - 0.5
                hitboxes[k.frame + 1] = k.bounds
            end
            -- If data is set to once, dont interpolate
            if slice.data ~= "once" then
                -- Forward pass to fill empty frames
                for i, _ in ipairs(frames) do
                    hitboxes[i] = hitboxes[i] or hitboxes[i - 1]
                end
                -- Backwords pass
                for i, _ in ipairs(frames) do
                    local s = hitboxes:size()
                    local index = s - i + 1
                    hitboxes[index] = hitboxes[index] or hitboxes[index + 1]
                end
            end
            -- Filter pass
            local function get_limits()
                local hb_mask = frame_hitbox_mask[slice.name] or {}
                return hb_mask.from or 1, hb_mask.to or #frames
            end

            local hb_to, hb_from = get_limits()

            for i = 1, hb_to - 1 do
                hitboxes[i] = nil
            end
            for i = hb_from + 1, #frames do
                hitboxes[i] = nil
            end
            -- Fill pass
            for i, f in ipairs(frames) do
                frames[i].hitbox[slice.name] = hitboxes[i]
            end

        end
        -- Fill in tags
        local tags = Dictionary.create()
        for _, tag in pairs(data.meta.frameTags) do
            tags[tag.name] = tag
        end
        this.frames[name] = frames
        this.tags[name] = tags
    end
    return setmetatable(this, Atlas)
end

function Atlas:get_animation(name)
    local name, tag_name = unpack(string.split(name, '/'))
    local frames = self.frames[name]
    if not tag_name then return frames end
    local tag = self.tags[name][tag_name]
    if not tag then return frames end
    return frames:sub(tag.from + 1, tag.to + 1)
end

function Atlas:sprite(aliases)
    return Sprite.create(self, aliases)
end

function Atlas:get_quads(name)
    local frames = self:get_animation(name)
    if not frames then
        log.warn("Unknown quads <%s>", name)
        return
    else
        return frames:map(function(f) return f.quad end)
    end
end

function Atlas:draw(frame, origin, x, y, r, sx, sy)
    if type(frame) == "string" then
        local f = self:get_animation(frame)
        return self:draw(f:head(), nil, origin, x, y, r, sx, sy)
    end
    local cx, cy = 0, 0
    if origin and frame.hitbox[origin] then
        local center = frame.hitbox[origin]
        cx, cy = center.cx, center.cy
    end
    gfx.draw(
        self.sheet, frame.quad, x,  y, r, sx, sy, -frame.ox + cx, -frame.oy + cy
    )
end

return Atlas
