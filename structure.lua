local structure = {}
structure.__index = structure

function structure.create(master)
    local this = {
        -- Relastions
        master = master,
    }
    return setmetatable(this, structure)
end

function structure:__call(...)
    if not self.frames then
        self.frames = self.master.build_structure(...)
        if self.master.commiter then
            self.commiter(self.frames, ...)
        end
    end

    return self.frames
end

function structure:clear()
    self.frames = nil
    return self
end

return function(...)
    return structure.create(...)
end
