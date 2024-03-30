local misc = {}

function misc.errorf(...) return error(string.format(...)) end

function misc.printf(...) return print(string.format(...)) end


return misc