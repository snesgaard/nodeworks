local hitbox_system = ecs.system(components.sprite, components.hitbox_collection)

function hitbox_system:update(dt)
    for _, entity in ipairs(self.pool) do
        local collection = entity[components.hitbox_collection]
        local sprite = entity[components.sprite]
        local slices = sprite[components.slices]
        local mirror = sprite[components.mirror]
        local body_slice = entity[components.body_slice] or components.body_slice()
        local body = slices[body_slice] or spatial()
        local c = body:centerbottom()

        local centered_slices = {}
        for key, slice in pairs(slices) do
            centered_slices[key] = slice:move(-c.x, -c.y)
            if mirror then
                centered_slices[key] = centered_slices[key]:hmirror(0, 0)
            end
        end

        entity:update(components.hitbox_collection, centered_slices)
    end
end

return {hitbox=hitbox_system}
