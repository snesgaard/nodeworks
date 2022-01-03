-- TODO Figure out how to more effectively queue actions

local event_queue = {}
event_queue.__index = event_queue

function event_queue.create()
    return setmetatable({spinning=false, queue=list()}, event_queue)
end

function event_queue:pop()
    if self.queue:empty() then return nil end
    local q = self.queue
    self.queue = list()
    return q
end

function event_queue:spin()
    if self.spinning then return self end

    self.spinning = true

    local function invoke(f, ...) return f(...) end
    local function handle(event)
        if #event > 10 then return invoke(unpack(event)) end
        local q = event
        return q[1](q[2], q[3], q[4], q[5], q[6], q[7], q[8], q[9], q[10])
    end

    local function handle_queue()
        local queue = self:pop()
        if not queue then return end

        local s = #queue
        for i = 1, s do
            handle(queue[i])
            handle_queue()
        end
    end

    handle_queue()

    self.spinning = false

    return self
end

function event_queue:add_without_spin(f, ...)
    self.queue[#self.queue + 1] = {f, ...}
    return self
end

function event_queue:add(f, ...)
    return self:add_without_spin(f, ...):spin()
end

function event_queue:__call(...) return self:add(...) end

return event_queue
