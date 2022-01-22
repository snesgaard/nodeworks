local nw = require "nodeworks"
local gui = nw.nodegui

local function id_from_tag(tag) return tag end
local function text_from_tag(tag) return tag end

local core = {}
core.__index = core

function core.create()
    return setmetatable(
        {
            states = {},
            layout = gui.layout(),
            graph = gui.graph(),
            focus = gui.focus(),
            elements = {},
            stack = gui.focus(),
            style = gui.style(),
            opts = {},
            shapes = {},
            events = {},
            layer = gui.layer()
        },
        core
    )
end

function core:set_events(events)
    self.events = events
    return self
end

function core:clear()
    self.layout = gui.layout()
    self.graph = gui.graph()
    self.focus = gui.focus()
    self.elements = {}
    self.stack = gui.focus()
    self.shapes = {}
    self.opts = {}
    self.style = gui.style()
    self.layer = gui.layer()
    return self
end

function core:set_shape(id, shape) self.shapes[id] = shape end

function core:shape(id) return self.shapes[id] end

function core:state(id)
    local s = self.states[id]
    if s then return s end
    local ns = {}
    self.states[id] = ns
    return ns
end

function core:draw()
    self.layer:draw()
end

function core:on_child(core, child_id)
    if not self.focus:empty() then return end
    self.focus:push(child_id)
end

function core:enter(element, tag, ...)
    local id = id_from_tag(tag)
    local parent = self.stack:peek()

    if self.elements[id] then
        errorf("An element with id %s already exists", tostring(id))
    end

    self.graph:link(parent or self, id)
    self.elements[id] = element

    if parent then
        local parent_element = self.elements[parent]
        if parent_element and parent_element.on_child then
            parent_element.on_child(self, parent, id)
        end
    else
        self.on_child(self, self, id)
    end


    self.stack:push(id)

    if element.on_enter then element.on_enter(self, id, ...) end

    if not self.shapes[id] then
        self.shapes[id] = self.layout:get()
    end
end

local function invoke_event(core, id, event_type, ...)
    local element = core.elements[id]
    local f = element[event_type]
    if not f then return false end
    f(core, id, ...)
end

function core:exit(...)
    local id = self.stack:pop()
    local element = self.elements[id]

    if element.on_exit then return element.on_exit(self, id, ...) end
end

function core:widget(...)
    self:enter(...)
    return self:exit(...)
end

return core.create
