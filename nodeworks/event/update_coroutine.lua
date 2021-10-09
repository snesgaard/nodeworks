coroutine._cleaners = {}
coroutine._threads = {}
coroutine._children = {}

local function get_children(co)
    if not coroutine._children[co] then
        coroutine._children[co] = {}
    end
    return coroutine._children[co]
end

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

    local children = get_children(co)

    for _, child in ipairs(children) do
        coroutine.cleanup(child)
    end

    coroutine._children[co] = {}

    return true
end

function coroutine.get(name)
    return coroutine._threads[name]
end

function coroutine.set(name, func, ...)
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
        local status, msg = coroutine.resume(co, ...)
        if not status then
            errorf("Error executing co, %s", msg)
        end
    end

    return co
end

function coroutine.child(thread_or_func, ...)
    local main = coroutine.running()

    if not main then
        errorf("Main cannot have children")
    end

    local co = thread_or_func
    local t = type(co)

    if t == "function" then
        co = coroutine.create(co)
        local status, msg = coroutine.resume(co, ...)
        if not status then
            errorf("Error executing co, %s", msg)
        end
    elseif t ~= "thread" then
        errorf("Type %f cannot be made a coroutine", t)
    end

    local children = get_children(main)
    table.insert(children, co)

    return coroutine
end
