local NodeA = Node.create(function(self)
    self:fork(function()
        local y = event:wait("/foo")
        assert(y)
        local y = event:wait("/foo")
        assert(not y)
    end)
end)

event:invoke("/foo", true)
event:spin()
NodeA:destroy()
event:invoke("/foo", true)
event:spin()