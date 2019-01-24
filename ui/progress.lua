return function(core, info, ...)
    local opt, x,y,w,h = core.getOptionsAndSize(...)
    info.min = info.min or math.min(info.value, 0)
	info.max = info.max or math.max(info.value, 1)
	info.step = info.step or (info.max - info.min) / 10
	local fraction = (info.value - info.min) / (info.max - info.min)
	local value_changed = false

    core:registerDraw(opt.draw or core.theme.Slider, fraction, opt, x,y,w,h)
end
