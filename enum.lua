return function(name)
    local ret = {}

    for _, n in ipairs(name) do
        ret[n] = n
    end

    return n
end
