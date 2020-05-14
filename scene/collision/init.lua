bump = require(... .. ".bump.bump")

require(... .. ".bumpdebug")

local api = {
    Body = require(... .. ".body"),
    Hitbox = require(... .. ".hitbox"),
    response = require(... .. ".response")
}

function api.init(world)
    for key, func in pairs(api.response) do
        world:addResponse(key, func)
    end
end

function api.sprite_hitbox_sync(body, slices)
    if not body:find("hitbox") then
        body:child("hitbox")
    end

    local master = body:find("hitbox")
    local children = master:children()

    for key, node in pairs(children) do
        if not slices[key] and key ~= ".." then
            node:destroy()
        end
    end

    for key, slice in pairs(slices) do
        if children[key] then
            local node = children[key]
            node:set_shape(slice)
        else
            local node = master:child(key, api.Hitbox, slice:unpack())
            node.name = key
        end
    end
end

return api
