local spatial_func = {
    {"set", {"x", "y", "w", "h"}},
    {"left", {"x", "y", "w", "h"}},
    {"right", {"x", "y", "w", "h"}},
    {"up", {"x", "y", "w", "h"}},
    {"down", {"x", "y", "w", "h"}},
    {"upright", {"x", "y", "w", "h"}},
    {"upleft", {"x", "y", "w", "h"}},
    {"downright", {"x", "y", "w", "h"}},
    {"downleft", {"x", "y", "w", "h"}},
    {"expand", {"dx", "dy", "align", "valign"}},
    {"align", {"xself", "xother", "yself", "yother"}}
}

local spatial_nodes = {}

for _, data in ipairs(spatial_func) do
    local name, args_name = unpack(data)
    local node = {}

    function node:begin(...)
        local function do_call(index, val, ...)
            if index > #args_name then return end
            self[args_name[index]] = val
            return do_call(index + 1, ...)
        end

        do_call(1, ...)
    end

    function node:memory()
        spatialstack:push()
    end

    function node:enter()
        local f = Spatial[name]

        function do_call(index, ...)
            if index <= 0 then
                return spatialstack:map(f, ...)
            end
            local key = args_name[index]
            return do_call(index - 1, self[key], ...)
        end

        do_call(#args_name)
    end

    function node:exit()
        spatialstack:pop()
    end

    spatial_nodes[name] = node
end

spatial_nodes.border_expand = {}

function spatial_nodes.border_expand:memory()
    spatialstack:push()
end

function spatial_nodes.border_expand:enter()
    local lw = gfx.getLineWidth()
    spatialstack:map(Spatial.expand, lw, lw)
end

function spatial_nodes.border_expand:exit()
    spatialstack:pop()
end

return spatial_nodes
