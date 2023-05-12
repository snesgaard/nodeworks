local nw = require "nodeworks"
local stack = nw.ecs.stack

local function event_back()
    return dict{
        all = list(),
        keyed = dict()
    }
end

local function event_front(back) return back or event_back() end

local constant = {
    empty = list(),
    id = "system::event"
}

local event = {}

function event.emit(key, ...)
    local args = {...}
    local es = stack.ensure(event_back, constant.id)
    table.insert(es.all, {key=key, args=args})
    local sub = es.keyed[key] or list()
    table.insert(sub, args)
    es.keyed[key] = sub
end

function event.get(key)
    local front = stack.ensure(event_front, constant.id)
    return front.keyed[key] or constant.empty
end

local function view_iterator(view_list, index)
    local index = index or 1
    local value = view_list[index]
    if not value then return end
    return index + 1, unpack(value)
end

function event.view(key)
    return view_iterator, event.get(key)
end

function event.get_all(key)
    local front = stack.ensure(event_front, constant.id)
    return front.all
end

function event.spin()
    local eb = stack.ensure(event_back, constant.id)
    stack.remove(event_back, constant.id)
    stack.set(event_front, constant.id, eb)
    return eb.all:size()
end

return event