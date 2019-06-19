local argmap = dict{
    move = "moveTo",
    lifetime = "setParticleLifetime",
    rate = "setEmissionRate",
    area = "setEmissionArea",
    spread = "setSpread",
    size = "setSizes",
    speed = "setSpeed",
    dir = "setDirection",
    damp = "setLinearDamping",
    color = "setColors",
    acceleration = "setLinearAcceleration",
    tangential_acceleration = "setTangentialAcceleration",
    relative_rotation = "setRelativeRotation",
    rotation = "setRotation",
    quad = "setQuads",
    spin = "setSpin",
    offset = "setOffset",
    pos = "setPosition",
    emit = "emit",
    stop = "stop",
    size_var= "setSizeVariation",
}

local function apply_api(particle, key, value)
    api = argmap[key]

    if not api then
        log.warn("Key %s not present in map", key)
        return
    end

    local f = particle[api]
    if not f then
        log.warn("Key is %s not a member", key)
        return
    end

    if type(value) == "table" then
        local status, msg = pcall(f, particle, unpack(value))
        if not status then
            msg = string.format("Error while calling <%s>: %s", key, msg)
            error(msg)
        end
    else
        local status, msg = pcall(f, particle, value)
        if not status then
            msg = string.format("Error while calling <%s>: %s", key, msg)
            error(msg)
        end
    end
end

return function(arg)
    if not arg.image and arg.atlas then
        arg.image = arg.atlas.sheet
    end

    local im = arg.image
    local buffer = arg.buffer

    if type(im) == "string" then
        im = gfx.newImage(im)
    end

    local p = gfx.newParticleSystem(im, buffer)

    for key, value in pairs(arg) do
        if key ~= "image" and key ~= "buffer" and key ~= "atlas" and key ~= "stop" and key ~= "emit" then
            apply_api(p, key, value)
        end
    end

    if arg.emit then
        p:emit(arg.emit)
    end

    if arg.stop then
        p:stop()
    end

    return p
end
