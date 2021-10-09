return {
    enter = function(node, args)
        args.transforms = args.transforms or list()
        --if node.transform then
        --    table.insert(args.transforms, 1, node.transform)
        --end
        args.transforms[#args.transforms + 1] = node.transform
    end,
    visit = function(node, args)
        if node.update then
            node:update(args.dt, args)
        end
    end,
    exit = function(node, args, info)
        if node.transform then
            --args.transforms = args.transforms:body()
            args.transforms[#args.transforms] = nil
        end
    end
}
