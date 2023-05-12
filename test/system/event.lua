stack = nw.ecs.stack
event = nw.system.event

T("test_event", function(T)
    event.emit("update", 1)
    event.emit("bar", 1, 2, 3)
    event.emit("update", 2)

    T:assert(event.get("update"):size() == 0)

    T:assert(event.spin() == 3)

    T:assert(event.get("update"):size() == 2)
    T:assert(event.get("bar"):size() == 1)
    T:assert(event.get_all():size() == 3)

    local sum_of_time = 0
    for _, dt in event.view("update") do
        sum_of_time = sum_of_time + dt
    end

    T:assert(
        event.get_all():map(function(e) return e.key end) == list("update", "bar", "update")
    )

    T:assert(sum_of_time == 3)

    T:assert(event.spin() == 0)
end)