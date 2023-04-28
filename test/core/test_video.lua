local idle = list(
    {dt = 1},  {dt = 2}, {dt = 3}
)

T("test_video", function(T)
    local video = Video.create(idle)

    T("play", function(T)
        video:once()
        T:assert(video:argframe() == 1)
        T:assert(not video:update(0.5))
        T:assert(video:update(1))
        T:assert(video:argframe() == 2)
        T:assert(video:update(2))
        T:assert(video:argframe() == 3)
        T:assert(not video:update(1000))
    end)

    T("play_with_loop", function(T)
        video:loop()
        T:assert(video:update(5.5))
        T:assert(video:argframe() == 3)
        T:assert(video:update(1))
        T:assert(video:argframe() == 1)
    end)

    T("negative_time", function(T)
        T:assert(video:loop():argframe(-1) == 3)
    end)

    T("is_done", function(T)
        video:once()
        T:assert(not video:is_done(0))
        T:assert(not video:is_done(5))
        T:assert(video:is_done(7))
    end)
end)