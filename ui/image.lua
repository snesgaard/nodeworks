return function(core, image, ...)
    core:registerDraw(function(image, ...)
		love.graphics.draw(image, ...)
	end, image, ...)
end
