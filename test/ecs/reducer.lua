local nw = require "nodeworks"
local T = nw.third.knife.test
local Reducer = nw.ecs.reducer
local epoch = Reducer.epoch

local id = {player = "player", foe = "doe"}

local component = {}

function component.health(hp) return hp or 0 end

function component.poison(p) return p or 0 end

function component.thorns(t) return t or 0 end

function component.drain(d) return d or 0 end

local map = {}

function map.attack(state, user, target, damage)
    local damage = {"damage", target, damage}
    local drain = {
        "heal", user,
        function(record)
            local damage_info = record:info(damage)
            local drain = record:state():get(component.drain, user) or 0
            return math.floor(damage_info.damage * drain)
        end
    }
    local thorns = {"thorns", user, target}
    local info = {damage = damage}
    local epoch = epoch(state)

    return epoch, list(damage, drain, thorns)
end

function map.thorns(state, user, target)
    local thorns = state:get(component.thorns, target) or 0
    if 0 < thorns then
        return epoch(state), list({"damage", user, thorns})
    else
        return epoch(state)
    end
end

function map.damage(state, target, damage)
    local next_state = state:copy()
        :map(component.health, target, function(hp)
            return hp - damage
        end)

    local info = {damage = damage}

    return epoch(next_state, info)
end

function map.heal(state, target, heal)
    local next_state = state:copy()
        :map(component.health, target, function(hp)
            return hp + heal
        end)

    local info = {heal = heal}

    return epoch(state, info)
end

T("reducer", function(T)
    local intial_state = nw.ecs.entity.create()
        :set(component.health, id.player, 10)
        :set(component.health, id.foe, 5)

    local reducer = Reducer.create(nw.ecs.entity).create(intial_state, map)

    T("damage", function(T)
        local record = reducer:run{"damage", id.foe, 5}
        T:assert(record:state():get(component.health, id.foe), 0)
    end)

    T("attack_w_thorns", function(T)
        reducer.state:set(component.thorns, id.foe, 2)
        local record = reducer:run{"attack", id.player, id.foe, 3}

        T:assert(record:state():get(component.health, id.foe), 2)
        T:assert(record:state():get(component.health, id.player), 8)

        local expected_actions = {
            "attack", "damage", "heal", "thorns", "damage"
        }
        local actions = record:epochs():map(function(e) return e.action[1] end)
        T:assert(table_equal(actions, expected_actions))
    end)

    T("attack_w_drain", function(T)
        reducer.state:set(component.drain, id.player, 2)

        local attack = {"attack", id.player, id.foe, 3}
        local record = reducer:run(attack)

        local heals = record:epochs():filter(function(e) return e.action[1] == "heal" end)
        T:assert(heals:size() == 1)
        local heal = heals:head()
        T:assert(heal.info.heal == 6)
    end)

    T("attack_inspection", function(T)
        local record = reducer:run{"attack", id.player, id.foe, 4}

        local damage = record:children(record:root())
            :filter(function(e) return e.action[1] == "damage" end)
            :head().info.damage

        T:assert(damage == 4)
    end)

end)
