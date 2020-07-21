local damage = ecs.system({components.health})

function damage:attack(args)
    local target = args[components.target]

    if not self.pool[target] then return end

    
end
