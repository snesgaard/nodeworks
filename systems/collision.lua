local system = ecs.system.from_function(
    function(entity)
        return {
            pool = entity[components.bump_world] and (entity[components.body or entity[components.hitbox])
        }
    end
)

return system
