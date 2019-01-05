local functors = {}



local box = {}
box.__index = box

function box.create(map, parent)
    local this = {}

    local function get_super()
        if not parent then return nil end

        local function callback(...)
            local p, s = this._map(...)
            self._pos, self._size = p, s
            this.on_change(p, s)
        end

        callback(parent._pos, parent._size)

        parent.on_change:listen(callback)
    end

    this._pos = vec2(0, 0),
    this._size = vec2(0, 0),
    this._map = map or function(...) return ... end,
    this.on_change = event(),
    this._super = get_super(),

    return setmetatable(this, box)
end

function box:child(map)
    return box.create(map, self)
end

function box:set_size(size)
    self._size = size
    return self:broadcast()
end

function box:set_pos(pos)
    self._pos = pos
    return self:broadcast()
end

function box:broadcast()
    self.on_change(self._pos, self._size)
    return self
end

function box:move(motion)
    local function map(pos, size)
        return pos + motion, size
    end

    return self:child(map)
end

function box:xalign(src, side, margin)
    local function map(dst_pos, dst_size, src_pos, src_size)

    end
end

function box
