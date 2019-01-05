function structure.create(creator)
    local this = {
        -- Relastions
        creator = creator,
    }
    return setmetatable(this, structure)
end

function structure:set_creator(c)
    self.creator = c
    self:clear()
    return self
end

function structure:get(...)
    if not self.frames then
        self.frames = self.creator(...)
    end

    return self.frames
end

function structure:clear()
    self.frames = nil
    return self
end

return function()
    return structure.create()
end
