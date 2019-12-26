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
            frames[#frames + 1] = Frame.create(sheet, {}, quad, vec2(ox, oy))
            frames[#frames]:set_dt(dt)
        end
        -- Update slices with a central bound

        for _, slice in pairs(data.meta.slices) do
            local hitboxes = List.create()
            local delta = List.create()
            local delta_init = List.create()
            for _, k in ipairs(slice.keys) do
                hitboxes[k.frame + 1] = spatial(
                    k.bounds.x, k.bounds.y, k.bounds.w, k.bounds.h
                )
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
                delta[i] = nil
                delta_init[i] = nil
            end
            for i = hb_from + 1, #frames do
                hitboxes[i] = nil
                delta[i] = nil
                delta_init[i] = nil
            end
            -- Fill pass
            for i, f in ipairs(frames) do
                frames[i].slices[slice.name] = hitboxes[i]
                frames[i].slices_origin[slice.name] = hitboxes[1]
                frames[i].frame_id = name
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

local function get_tag_limit(self, frames, name, tag_name)
    local default = {from = 0, to = #frames - 1}
    if not tag_name or not self.tags[name][tag_name]  then
        return default
    else
        return self.tags[name][tag_name]
    end
end

function Atlas:get_animation(name)
    local name, tag_name = unpack(string.split(name, '/'))

    local frames = self.frames[name]
    local tag = get_tag_limit(self, frames, name, tag_name)

    local frames_sub = frames:sub(tag.from + 1, tag.to + 1)

    return frames_sub
end

function Atlas:get_frame(name)
    return self:get_animation(name):head()
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
    if frame.hitbox[origin] then
        local center = frame.hitbox[origin]
        cx, cy = center.cx, center.cy
    end
    gfx.draw(
        self.sheet, frame.quad, x,  y, r, sx, sy, -frame.ox + cx, -frame.oy + cy
    )
end


local function anime2animation(name, frames, player)
    if not frames then return end

    local time_deltas = frames:map(function(f) return f.dt end)
    local times = time_deltas:scan(function(a, b)
        return a + b
    end, 0)
    local duration = times[#times]
    times[#times] = nil
    local images = frames:map(function(f) return f.image end)
    local quads = frames:map(function(f) return f.quad end)
    local offsets = frames:map(function(f) return f.offset end)
    local center = frames
        :map(function(f) return f.slices.origin:center() end)

    player:animation(name)
        :track("../sprite/offset", times, offsets)
        :track("../sprite/image", times, images)
        :track("../sprite/quad", times, quads)
        :track("../sprite/center", times, center)
        :duration(duration)
end

function Atlas:animation_player(animations, player)
    player = player or Node.create(animation_player)

    for name, anime_key in pairs(animations) do
        anime2animation(name, self:get_animation(anime_key), player)
    end

    return player
end

return Atlas
