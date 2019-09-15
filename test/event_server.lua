local es = event_server()

local co1 = coroutine.create(function()
    local a = es:wait("this thing")
    assert(a == 1)
    es:invoke("another thing", 2)
    assert(es:wait("third thing") == 3)
end)

local co2 = coroutine.create(function()
    es:invoke("this thing", 1)
    assert(es:wait("another thing") == 2)
    es:invoke("third thing", 3)
end)

coroutine.resume(co1)
coroutine.resume(co2)

es:spin()

assert(is_empty(es._address))

es = event_server()

local token = {}

local co1 = coroutine.create(function()
    assert(es:wait(token, "this is it"))
end)

local co2 = coroutine.create(function()
    es:invoke(token, "not this", false)
    es:invoke(token, "not this either", false)
    es:invoke({}, "false", false)
    es:invoke({}, "this is it", false)
    es:invoke(token, "this is it", true)
end)

coroutine.resume(co1)
coroutine.resume(co2)

es:spin()

assert(is_empty(es._address))

es = event_server()

local context = {count = 0}

local function callback(val)
    assert(val)
    context.count = context.count + 1
end

local token = es:listen("thing", callback)

es:invoke("thing", true)
es:invoke("thing", true)

es:spin()

es:clear(token)

es:invoke("thing", false)

assert(context.count == 2)
assert(is_empty(es._address))

es = event_server()

local context = {}

local function callback(val)
    assert(val)
    return false
end

context.token = es:listen("thing", callback)

es:invoke("thing", true)
es:invoke("thing", false)

es:spin()

assert(is_empty(es._address))

es = event_server()

es:invoke("thing", true)

local function callback(val)
    assert(false)
end

local co = coroutine.create(function()
    es:wait("thing")
    assert(false)
end)

coroutine.resume(co)

es:listen("thing", callback)
es:close("thing")
es:invoke("thing", false)
es:spin()


es = event_server()

es:invoke("thing", true)

local function callback(val)
    assert(false)
end

local co = coroutine.create(function()
    es:wait("thing")
    assert(false)
end)

coroutine.resume(co)

local token = es:listen("thing", callback)
es:clear(co)
es:clear(token)
es:invoke("thing", false)
es:spin()

es = event_server()

local token = {}
local co = coroutine.create(function()
    es:wait(token, "obey")
    es:wait(token, "blarg")
    assert(false, "for some reason, was double invoked")
end)

coroutine.resume(co)
es:invoke(token, "obey")
es:invoke(token, "obey")
es:spin()
