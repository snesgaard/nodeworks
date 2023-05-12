local WeakID = class()

function WeakID.constructor(tag)
    return {tag=tag or "generic"}
end

function WeakID:__tostring()
    return string.format("__WeakID[%s]", tostring(self.tag))
end

local StrongID = {
    counters = {}
}

function StrongID.get(tag)
    local tag = tag or "generic"
    local c = StrongID.counters[tag] or 1
    StrongID.counters[tag] = c + 1
    return c
end

local id = {}

function id.strong(tag)
    local c = StrongID.get(tag)
    return string.format("%s[%i]", tostring(tag), c)
end

function id.weak(tag) return WeakID.create(tag) end

return id