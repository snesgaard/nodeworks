local path = (...):gsub("atlas", "")

---@module "misc"
local misc = require(path .. "misc")
---@module "frame"
local frame = require(path .. "frame")
---@module "list"
local list = require(path .. "list")
---@module "vec2"
local vec2 = require(path .. "vec2")
---@module "spatial"
local spatial = require(path .. "spatial")
---@module "love"
local love = require "love"
---@module "3rd"
local third = require "3rd"
---@module "nodeworks.core.video"
local video = require "nodeworks.core.video"

local gfx = love.graphics


local function read_json(path)
    -- Load nodeworks here to avoid infinite loop
    local data, err = love.filesystem.newFileData(path)
    if data:getExtension() == 'json' then
        return third.json.decode(love.filesystem.read(path))
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


local function slice_outside_frame(slice, w, h)
    local x_outside = w <= slice.x or slice.x + slice.w < 0
    local y_outside = h <= slice.y or slice.y + slice.h < 0
    return x_outside or y_outside
end

---@param slice_data string
---@return table
local function decode_slice_data(slice_data)
    if not slice_data then return {} end
    return third.json.decode(slice_data)
end

---@class AsepriteSize
---@field w integer
---@field h integer

---@class AsepriteFrameBound
---@field x integer
---@field y integer
---@field w integer
---@field h integer

---@class AsepriteFrameData
---@field filename string
---@field frame AsepriteFrameBound
---@field rotated boolean
---@field trimmed boolean
---@field spriteSourceSize AsepriteFrameBound
---@field sourceSize AsepriteSize
---@field duration integer

---@class FrameTag
---@field from integer
---@field to integer


---@class AsepriteSliceInstance
---@field frame integer
---@field bounds AsepriteFrameBound

---@class AsepriteSlice
---@field name string
---@field data string
---@field color string
---@field keys AsepriteSliceInstance[]
---@field from integer
---@field to integer

---@class Atlas
---@field path string
---@field frames frame[]
---@field tags table<string, FrameTag> 
---@field sheet love.Image
local Atlas = misc.class()

---@param sheet love.Image
---@param path string?
---@return Atlas
local function new(sheet, path)
    return setmetatable(
        {
            frames = {}, --List.create(),
            tags   = {}, --Dictionary.create(),
            sheet  = sheet,
            path = path,
        },
        Atlas
    )
end

---@param path string
---@return Atlas
function Atlas.from_file(path)
    local sheet = gfx.newImage(path .. "/atlas.png")
    local data = read_json(path   .. "/atlas.json")

    return Atlas.create(sheet, data)
end

---@param frame_data AsepriteFrameData
---@param sheet love.Image
---@return love.Quad
local function quad_from_frame_data(frame_data, sheet)
    -- ASsume a 1px margin
    local x = frame_data.frame.x + 1
    local y = frame_data.frame.y + 1
    local w, h = frame_data.frame.w - 2, frame_data.frame.h - 2
    if love.window then
        return gfx.newQuad(x, y, w, h, sheet:getDimensions())
    else
        return {
            getViewport = function() return x, y, w, h end
        }
    end
end

---@param frame_data  AsepriteFrameData
---@return number
local function duration_from_frame_data(frame_data)
    return frame_data.duration / 1000.0
end

---@param frame_data  AsepriteFrameData
---@return vec2
local function offsets_from_frame_data(frame_data)
    local ox, oy = frame_data.spriteSourceSize.x, frame_data.spriteSourceSize.y
    return vec2(ox, oy)
end

---@param sheet love.Image
---@param data table
function Atlas.create(sheet, data)
    local this = new(sheet, path)

    ---@type AsepriteFrameData[]
    local frame_datas = data.frames

    local quads = list.map(frame_datas, quad_from_frame_data, sheet)
    local durations = list.map(frame_datas, duration_from_frame_data)
    local offsets = list.map(frame_datas, offsets_from_frame_data)

    ---@type AsepriteSlice[]
    local aseprite_slice_datas = data.meta.slices
    ---@type table<string, Spatial>[]
    local all_slices = {}
    ---@type table<string, table>[]
    local all_slice_datas = {}

    for _, aseprite_slice in ipairs(aseprite_slice_datas) do
        local name = aseprite_slice.name
        local aseprite_slice_data = decode_slice_data(aseprite_slice.data)

        ---@type Spatial[]
        local bounds = {}
        
        -- Populate all discrete instances
        for _, s in ipairs(aseprite_slice.keys) do
            local index = s.frame + 1
            
            bounds[index] = spatial(
                s.bounds.x, s.bounds.y, s.bounds.w, s.bounds.h
            )
        end

        -- Forward interpolation
        local to = aseprite_slice.to + 1
        local from = aseprite_slice.from + 1
        for i = from, to do
            bounds[i] = bounds[i] or bounds[i - 1]
        end

        -- Backwards interpolation
        for i = to, from, -1 do
            bounds[i] = bounds[i] or bounds[i + 1]
        end

        -- Assign to global list
        for i = from, to do
            all_slices[i] = all_slices[i] or {}
            all_slice_datas[i] = all_slice_datas[i] or {}

            all_slices[i][name] = bounds[i]
            all_slice_datas[i][name] = aseprite_slice_data
        end
    end

    -- Create frames
    for i = 1, #frame_datas do
        this.frames[i] = frame.new(
            sheet,
            all_slices[i] or {},
            quads[i],
            durations[i],
            all_slice_datas[i] or {},
            offsets[i]
        )
    end

    -- Prune slices out of bounds
    for i, frame in ipairs(this.frames) do
        local size = frame_datas[i].sourceSize
        for name, slice in pairs(frame.slices) do
            if slice_outside_frame(slice, size.w, size.h) then
                frame.slices[name] = nil
            end
        end
    end

    -- Create tags
    for _, tag in ipairs(data.meta.frameTags) do
        this.tags[tag.name] = {to = tag.to + 1, from = tag.from + 1}
    end

    return this
end

---@param name string
---@return frame[]
function Atlas:get_animation(name)
    local tag = self.tags[name]

    if not tag then
        error(string.format("Could not find animation: %s", name))
    end

    local frames_sub = list.sublist(self.frames, tag.from, tag.to)

    return frames_sub
end

---@param name string
---@return Video
function Atlas:get_video(name)
    return video(self:get_animation(name))
end

---@param name string
---@return frame|nil
function Atlas:get_frame(name)
    return self:get_animation(name)[1]
end

function Atlas:get_tags()
    local tags = {}

    for tag, _ in pairs(self.tags) do
        table.insert(tags, tag)
    end

    return unpack(tags)
end

return Atlas
