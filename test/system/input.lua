local input = nw.system.input
local event = nw.system.event

T("input", function(T)
    input.keypressed("k")
    event.spin()
    T:assert(input.is_pressed("k"))
    event.spin()
    T:assert(not input.is_pressed("k"))
end)