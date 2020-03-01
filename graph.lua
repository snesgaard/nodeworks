local graph = {}

local null = {}

function graph.traverse(graph, nodes, proc, args)
    args = args or {}
    local key = args.root or "root"

    local function do_traverse(key)
        local node = nodes[key] or null

        local info = proc.enter and proc.enter(node, args) or {}
        if proc.visit then proc.visit(node, args, info) end

        local children = graph[key]

        if children then
            for key, child in ipairs(children) do
                do_traverse(child)
            end
        end

        if proc.exit then proc.exit(node, args, info) end
    end

    return do_traverse(key)
end

function graph.prune(graph, nodes, args)
    args = args or {}
    local key = args.root or "root"

    local function do_traverse(key, should_remove)
        local node = type(key) == "table" and key or (nodes[key] or null)
        local children = graph[key]

        if not should_remove and node.prune then
            if type(prune) == "function" then
                should_remove = node:prune()
            else
                should_remove = nodes.prune
            end
        end

        if should_remove then
            graph[key] = nil
        end
        if should_remove and not args.retain then
            if node.on_prune then node:on_prune() end
            nodes[key] = nil
        end

        if children then
            for _, child  in ipairs(children) do
                local child_dead = do_traverse(child, should_remove)
            end
        end

        return should_remove
    end

    return do_traverse(key, false)
end

function graph.node(super, ...)
    super.__index = super.__index or super
    local this = {}
    setmetatable(this, super)
    if this.create then this:create(...) end
    return this
end

function graph.terminate(nodes, name)
    local n = nodes[name]
    if not n then return end
    nodes[name] = nil
    if n.on_pruned then
        n:on_pruned()
    end
end

return graph
