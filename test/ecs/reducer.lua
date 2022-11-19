local nw = require "nodeworks"
local T = nw.third.knife.test
local Reducer = nw.ecs.reducer
local epoch = Reducer.epoch

local component = {}

function component.health(value, max_value)
    return {value=value, max=max_value or value}
end

function component.strength(str) return str or 0 end

function component.armor(arm) return arm or 0 end

function component.poison(p) return p or 0 end

function component.shield() return true end

local functor = {}

function functor.attack(state, user, target, damage)
    local str = state:ensure(component.strength, user)
    local arm = state:ensure(component.armor, target)
    local real_damage = math.max(0, damage + str - arm)

    local actions = list(
        {"damage", target, real_damage, tag="damage"},
        {"apply_poison", target, function(record)
            local epoch = record:find("damage")
            return epoch:info().damage > 0 and 1 or 0
        end}
    )

    local info = dict{
        user = user,
        target = target,
        real_damage = real_damage
    }

    return epoch(state, info, actions)
end

function functor.damage(state, target, damage)
    local hp = state:get(component.health, target)
    if not hp then return end

    local real_damage = math.min(hp.value, damage)

    local shield = state:get(component.shield, target)

    if shield then real_damage = 0 end

    state:set(component.health, target, hp.value - real_damage, hp.max)

    local info = dict{
        damage = real_damage,
        target = target,
        shield = shield
    }

    return epoch(state, info)
end

function functor.apply_poison(state, target, poison)
    if poison <= 0 then return end

    state:map(component.poison, target, function(p) return p + poison end)

    local info = dict{
        target = target,
        poison = poison
    }

    return epoch(state, info)
end

local id = {
    player = "player",
    foe = "foe"
}

T("reducer", function(T)
    local state = nw.ecs.entity.create()
        :set(component.health, id.foe, 20)
        :set(component.health, id.player, 10)

    local reducer = Reducer.create(state, functor)
    local record = reducer:speculate({"attack", id.player, id.foe, 5, tag="action"})
    T:assert(record.epochs:size() == 3)
    local epoch_types = record.epochs:map(function(e) return e.type end)
    T:assert(epoch_types == list("attack", "damage", "apply_poison"))
    T:assert(record:state() ~= state)
    T:assert(record:state():get(component.health, id.foe).value == 15)
    T:assert(record:find("action"))
    T:assert(record:find("action").type == "attack")
end)
