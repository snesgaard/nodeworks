local WeakTable = {__mode = "k", __index = Dictionary}

function WeakTable.instance()
    return setmetatable({}, WeakTable)
end

local World = class()

function World.constructor(previous_components)
    local this = {
        component_tables = {},
        copy_on_write = {},
    }

    if previous_components then
        for comp, tab in pairs(previous_components) do
            this.component_tables[comp] = tab
            this.copy_on_write[comp] = true
        end
    end

    return this
end

function World:copy() return World.create(self.component_tables) end

function World:get_table(component, respect_cow)
    if type(component) ~= "function" then
        errorf("Component must be a function, but was %s", type(component))
    end
 
    local c = self.component_tables[component]
    if not c then
        local c = WeakTable.instance()
        self.component_tables[component] = c
        return c
    end

    if not self.copy_on_write[component] or not respect_cow then return c end
    
    local next_c = deepcopy(c)

    self.copy_on_write[component] = nil
    self.component_tables[component] = next_c
    return next_c

end

function World:get(component, id)
    return self:get_table(component)[id]
end

function World:set(component, id, ...)
    local c = self:get_table(component, true)
    local value = component(...)
    c[id] = value
    return self
end

function World:has(component, id)
    local v = self:get(component, id)
    return v ~= nil
end

function World:ensure(component, id, ...)
    self:init(component, id, ...)
    return self:get(component, id)
end

function World:init(component, id, ...)
    if not self:has(component, id) then self:set(component, id, ...) end
    return self
end

function World:remove(component, id)
    local c = self:get_table(component)
    c[id] = nil
    return self
end

function World:destroy(id)
    for _, tab in pairs(self.component_tables) do tab[id] = nil end
end

function World:visit(func, ...)
    if type(func) ~= "function" then
        errorf("Visiter must be function, but was %s", type(func))
    end
    func(self, ...)
    return self
end

local function assemble_format(id, comp, ...)
    return comp, id, ...
end

function World:assemble(values, id)
    for _, v in ipairs(values) do
        if type(v) ~= "table" then errorf("Values must be tables") end
        local c = v[1]
        if c then self:set(assemble_format(id, unpack(v))) end
    end
    return self
end

function World:view_table(component)
    return next, self:get_table(component)
end

return World.create