local PATH = ...

return {
    knife = {
        test = require(PATH .. ".knife.knife.test"),
    },
    bump = require(PATH .. ".bump.bump"),
    json = require(PATH .. ".json"),
    sti = require(PATH .. ".Simple-Tiled-Implementation.sti")
}
