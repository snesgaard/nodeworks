local nw = require "nodeworks"
local T = nw.third.knife.test
local Reducer = nw.ecs.reducer
local epoch = Reducer.epoch

local id = {player = "player", foe = "doe", other="other"}

local component = {}

function component.health(hp) return hp or 0 end

function component.poison(p) return p or 0 end

function component.thorns(t) return t or 0 end

function component.drain(d) return d or 0 end

local functor = {}

function functor.attack(state, from, to, base_dmg)
    local str = state:ensure(component.strength, from)
    local arm = state:ensure(component.armor, to)
    local dmg = base_dmg + str - arm

    local info = {
        from = from,
        to = to,
        dmg = dmg
    }

    local actions = list(
        {"damage", to, dmg, alias="attack_damage"}
    )

    return state, info, actions
end

function functor.attack_with_drain(state, from, to, base_dmg)
    local attack_action = list(
        {"attack", from, to, base_dmg, alias="attack_drain"},
        {"heal", from, function(record)
            return record:find("attack_drain")
                :and_then(function(node) return record:info(node) end)
                :map(function(info) return info.damage end)
                :value_or_default(0)
        end}
    )
end
