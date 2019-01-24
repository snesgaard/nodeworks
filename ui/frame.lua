-- This file is part of SUIT, copyright (c) 2016 Matthias Richter
return function(core, ...)
	local opt, x,y,w,h = core.getOptionsAndSize(...)
	opt.id = opt.id or {}

	core:registerDraw(opt.draw or core.theme.Frame, opt, x,y,w,h)

	return {}
end
