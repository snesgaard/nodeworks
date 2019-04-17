function compose(...)
    local arg = {...}
    return function(v)
        for _, f in ipairs(arg) do
            v = f(v)
        end
        return v
    end
end

function identity(...)
    return ...
end

function constant(...)
    local args = {...}
    return function()
        return unpack(args)
    end
end

function curry(f, ...)
    local args = {...}
    local n_args = #args

    if n_args < 1 then return f end

    return function(...)
        local a = {}
        for i, v in ipairs(args) do
            a[#a + 1] = v
        end
        for i, v in ipairs({...}) do
            a[#a + 1] = v
        end
        return f(unpack(a))
    end
end
