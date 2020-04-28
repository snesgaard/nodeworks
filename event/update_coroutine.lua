coroutine._cleaners = {}
coroutine._threads = {}

function coroutine.on_cleanup(f, co)
    co = co or coroutine.running()

    if not co then
        error("Can't setup cleanup on main thread")
    end

    log.debug("Setting cleanup %s", tostring(co))
    coroutine._cleaners[co] = f
end

function coroutine.cleanup(co)
    co = co or coroutine.running()

    if not co then return end

    local f = coroutine._cleaners[co]

    if not f then return end

    coroutine._cleaners[co] = nil
    f(co)
    return true
end

function coroutine.get(name)
    return coroutine._threads[name]
end

function coroutine.set(name, func, ...)
    log.debug("Setting %s: %s", name, tostring(func))
    local co = coroutine._threads[name]

    if co and co == coroutine.running() then
        error(string.format(
            "Don't swap from inside the same coroutine: %s",
            name
        ))
    end

    if co then
        coroutine.cleanup(co)
    end

    if co then
        event:clear(co)
        coroutine._threads[name] = nil
    end

    if func then
        local co = coroutine.create(func)
        coroutine._threads[name] = co
        coroutine.resume(co, ...)
    end

    return co
end
