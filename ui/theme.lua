local theme = {}

function theme.Frame(opt, x, y, w, h)
    local c = theme.getColorForState(opt)
    theme.drawBox(x, y, w, h, c, opt.cornerRadius)
end

function theme.Window(opt, x, y, draw)

end

return theme
