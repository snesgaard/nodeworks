local damage = ecs.system({components.health})

local poison = ecs.system({components.health, components.poison})

function poison:attack(event)
    local target = event[components.target]
    local damage = event[components.damage]

    if not target or not damage then return end
    if not self.pool[target] then return end
    if not damage.physical then return end

    damage.physical = damage.physical * 0.75
end

function poison:update(dt)
    local function __update(entity)
        local poison = entity[components.poison]
        local timer = poison[components.timer]

        if not timer:update(dt) then return end
        timer:reset()

        local health = entity[components.health]
        local multiplier = poison[components.multiplier] or 0
        local addition = poison[components.addition] or 0
        local damage = health.max * multiplier + addition;

        self:world():event(
            "attack",
            events.attack{
                [components.target]={entity},
                [components.damage]={{pure=damage}}
            }
        )

        if not tick:update() then return end

        entity:remove(components.poison)
    end

    lume.foreach(self:pool(), __update)
end

function poison:heal(args)
    local target = args[components.target]

    if not self.pool[args[target]] then return end

    args[components.heal] = 0
    entity:remove(components.poison)
end

local shield = ecs.system({components.shield})

function shield:attack(event)
    local target = event[component.target]

    if not self.pool[target] then return end

    local damage = event[component.damage]
    if not damage.physical then return end

    damage.physical = 0
    self.world("remove_component", target, components.shield)
end
