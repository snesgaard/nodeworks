local function sum_op(s, f) return s + f.dt end

local function sum_frame_time(frames)
    return List.reduce(frames, sum_op, 0)
end

local function arithmetic_fmod(num, denom)
    return num - math.floor(num / denom) * denom
end

local Video = class()

function Video.constructor(frames, init_time)
    local frames = frames or list()
    return {
        frames=frames,
        time=init_time or 0,
        total_time=sum_frame_time(frames),
        do_loop = true
    }
end

function Video:set_time(time)
    self.time = time or 0
    return self
end

function Video:loop()
    self.do_loop = true
    return self
end

function Video:once()
    self.do_loop = false
    return self
end

function Video:update(dt)
    local prev_index = self:argframe()
    self.time = self.time + dt
    local next_index = self:argframe()

    return prev_index ~= next_index
end

function Video:is_done(time)
    local time = time or self.time
    return self.total_time <= time
end

function Video:argframe(time, do_loop)
    local time = time or self.time
    local do_loop = do_loop or self.do_loop
    if do_loop then
        time = arithmetic_fmod(time, self.total_time)
    end

    for index, frame in ipairs(self.frames) do
        time = time - frame.dt
        if time < 0 then return index end
    end

    return List.size(self.frames)
end

function Video:frame(time, do_loop)
    local index = self:argframe(time, do_loop)
    return self:frame_from_index(index)
end

function Video:frame_from_index(index)
    return self.frames[index]
end

function Video.from_atlas(atlas_path, frame_path)
    local frames = get_atlas(atlas_path):get_animation(frame_path)
    return Video.create(frames)
end

return Video