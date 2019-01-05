local server = {}
server.__index = server

function server.create(self)
    self.queue = List.create()
    self.args = List.create()
    self.__wake = Event.create()
    self.on_action_done = Event.create()
    self.on_queue_empty = Event.create()
    self.on_release = Event.create()

    self:fork(self.process)
end

function server:process()
    if self.queue:size() == 0 then
        self.__asleep = true
        self:wait(self.__wake)
    end
    self.__asleep = false

    while self.queue:size() > 0 do
        local f = self.queue:head()
        self.queue = self.queue:body()
        local args = self.args:head()
        self.args = self.args:body()

        f(self, unpack(args))
        self.on_action_done(f, unpack(args))
    end

    self.on_queue_empty()

    return self:process()
end

function server:is_running()
    return self.__running
end

function server:add(f, ...)
    self.queue[#self.queue + 1] = f
    self.args[#self.args + 1] = {...}
    return self.__wake()
end

function server:for_finish()
    if not self.__asleep then
        return self.on_queue_empty
    end
end

return server
