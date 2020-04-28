local response = {}

function response.oneway_slide(world, col, x, y, w, h, goalX, goalY, filter)
    local slide, cross = bump.responses.slide, bump.responses.cross

    if col.normal.y < 0 and not col.overlaps then
        col.didTouch = true
        return slide(world, col, x, y, w, h, goalX, goalY, filter)
    else
        return cross(world, col, x, y, w, h, goalX, goalY, filter)
    end
end

return response
