local Atlas = {}
Atlas.__index = Atlas

function Atlas:__tostring()
    return string.format("Atlas <%s>", self.path)
end

local function read_file(path)
    local info = love.filesystem.getInfo(path .. '.lua')
    return info and require(path) or {}
end

local function read_json(path)
    -- Load nodeworks here to avoid infinite loop
    local nw = require "nodeworks"
    local data, err = love.filesystem.newFileData(path)
    if data:getExtension() == 'json' then
        return nw.third.json.decode(love.filesystem.read(path))
    else
        return {
            frames = {
                {
                    frame = {x = -1, y = -1, w = 0, h= 0},
                    duration = 1000, spriteSourceSize = {x = 0, y = 0}
                }
            },
            meta = {slices = {}, frameTags = {}}
        }
    end
end

local function get_event_tag(tag)
    return string.match(tag, "event<(.*)>")
end

local function slice_outside_frame(slice, w, h)
    local x_outside = w <= slice.x or slice.x + slice.w < 0
    local y_outside = h <= slice.y or slice.y + slice.h < 0
    return x_outside or y_outside
end

local function decode_slice_data(slice_data)
    if not slice_data then return {} end
    return dict(nw.third.json.decode(slice_data))
end

function Atlas.create(path)
    local sheet = gfx.newImage(path .. "/atlas.png")
    local data = read_json(path   .. "/atlas.json")

    local atlas_hitbox_mask = read_file(path .. "/hitbox")

    local this = {
        frames = List.create(),
        tags   = Dictionary.create(),
        slices = Dictionary.create(),
        sheet  = sheet,
        normal = normal,
        path = path,
    }

    local function calculate_border(lx, ux) return lx + ux end

    local dim = {sheet:getDimensions()}

    local frame_hitbox_mask = atlas_hitbox_mask[name] or {}
    local frames = this.frames
    for _, f in ipairs(data.frames) do
        local x = f.frame.x + 1
        local y = f.frame.y + 1
        -- ASsume a 1px margin
        local w, h = f.frame.w - 2, f.frame.h - 2
        local quad = gfx.newQuad(x, y, w, h, unpack(dim))
        local dt = f.duration / 1000.0
        local ox, oy = f.spriteSourceSize.x, f.spriteSourceSize.y
        frames[#frames + 1] = Frame.create(sheet, dict{}, quad, vec2(ox, oy))
        frames[#frames]:set_dt(dt)
        frames[#frames].name = f.filename
    end

    for _, tag in ipairs(data.meta.frameTags) do
        local name = tag.name

        local event = get_event_tag(name)
        if event then
            for i = tag.from + 1, tag.to + 1 do
                frames[i].events[event] = true
            end
        else
            if this.tags[name] then
                errorf("Naming conflict <%s>", name)
            end
            this.tags[name] = dict{to=tag.to, from=tag.from}
        end
    end


    -- Initial seeding of frames
    for _, slice in ipairs(data.meta.slices) do
        local name = slice.name

        local slice_data = decode_slice_data(slice.data)

        for _, key in ipairs(slice.keys) do
            local hitbox = spatial(
                key.bounds.x, key.bounds.y, key.bounds.w, key.bounds.h
            )
            local frame_index = key.frame + 1
            local frame = this.frames[frame_index]
            frame.slices[name] = hitbox
            frame.slice_data[name] = slice_data
        end

        -- Forward interpolation
        for i = slice.from + 2, slice.to + 1 do
            frames[i].slices[name] = frames[i].slices[name] or frames[i - 1].slices[name]
        end
        -- Backward interpolation
        for i = slice.to, slice.from + 1, -1 do
            this.frames[i].slices[name] = this.frames[i].slices[name] or this.frames[i + 1].slices[name]
        end
    end


    -- Fill slices, forward pass
    for tag_name, hitbox_mask in pairs(atlas_hitbox_mask) do
        local tag = this.tags[tag_name]
        if not tag then
            log.warn("Tag %s not found", tag_name)
        else
            for slice_name, mask in pairs(hitbox_mask) do
                for i = tag.from + 1, tag.to + 1 do
                    local frame = frames[i]
                    local local_index = i - tag.from
                    local should_remove = local_index < mask.from or mask.to < local_index
                    if should_remove then
                        frame.slices[slice_name] = nil
                    end
                end
            end
        end
    end

    --Remove slices that are outside the frame bound
    for index, frame in ipairs(this.frames) do
        local size = data.frames[index].sourceSize
        for name, slice in pairs(frame.slices) do
            if slice_outside_frame(slice, size.w, size.h) then
                frame.slices[name] = nil
            end
        end
    end

    -- Compute root motion
    for _, tag in pairs(this.tags) do
        local prev_body = nil
        for i = tag.from + 1, tag.to + 1 do
            local frame = frames[i]
            local body = frame.slices[Atlas.root_motion_slice]
            if prev_body and body then
                frame.root_motion = body:centerbottom() - prev_body:centerbottom()
            else
                frame.root_motion = vec2(0, 0)
            end
            if body then
                prev_body = body
            end
        end
    end

    return setmetatable(this, Atlas)
end

Atlas.root_motion_slice = "body"

function Atlas:get_animation(name)
    local tag = self.tags[name]

    if not tag then
        error(string.format("Could not find animation: %s", name))
    end

    local frames_sub = self.frames:sub(tag.from + 1, tag.to + 1)

    return frames_sub
end

function Atlas:get_frame(name)
    return self:get_animation(name):head()
end

function Atlas:get_tags()
    local tags = {}

    for tag, _ in pairs(self.tags) do
        table.insert(tags, tag)
    end

    return unpack(tags)
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

return Atlas
