---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local atlas_json = [[
    {
        "frames": [
            {
                "filename": "floppydisk.aseprite",
                "frame": {
                    "x": 1822,
                    "y": 0,
                    "w": 34,
                    "h": 34
                },
                "rotated": false,
                "trimmed": false,
                "spriteSourceSize": {
                    "x": 0,
                    "y": 0,
                    "w": 32,
                    "h": 32
                },
                "sourceSize": {
                    "w": 32,
                    "h": 32
                },
                "duration": 100
            },
            {
                "filename": "letter.aseprite",
                "frame": {
                    "x": 1723,
                    "y": 0,
                    "w": 66,
                    "h": 66
                },
                "rotated": false,
                "trimmed": false,
                "spriteSourceSize": {
                    "x": 0,
                    "y": 0,
                    "w": 64,
                    "h": 64
                },
                "sourceSize": {
                    "w": 64,
                    "h": 64
                },
                "duration": 100
            },
            {
                "filename": "main_gui.aseprite",
                "frame": {
                    "x": 0,
                    "y": 0,
                    "w": 642,
                    "h": 362
                },
                "rotated": false,
                "trimmed": false,
                "spriteSourceSize": {
                    "x": 0,
                    "y": 0,
                    "w": 640,
                    "h": 360
                },
                "sourceSize": {
                    "w": 640,
                    "h": 360
                },
                "duration": 100
            },
            {
                "filename": "main_menu.aseprite",
                "frame": {
                    "x": 642,
                    "y": 0,
                    "w": 628,
                    "h": 359
                },
                "rotated": false,
                "trimmed": true,
                "spriteSourceSize": {
                    "x": 0,
                    "y": 3,
                    "w": 626,
                    "h": 357
                },
                "sourceSize": {
                    "w": 640,
                    "h": 360
                },
                "duration": 100
            },
            {
                "filename": "objects.aseprite",
                "frame": {
                    "x": 1856,
                    "y": 0,
                    "w": 3,
                    "h": 3
                },
                "rotated": false,
                "trimmed": true,
                "spriteSourceSize": {
                    "x": 0,
                    "y": 0,
                    "w": 1,
                    "h": 1
                },
                "sourceSize": {
                    "w": 64,
                    "h": 64
                },
                "duration": 100
            },
            {
                "filename": "test-level.aseprite",
                "frame": {
                    "x": 642,
                    "y": 359,
                    "w": 322,
                    "h": 182
                },
                "rotated": false,
                "trimmed": false,
                "spriteSourceSize": {
                    "x": 0,
                    "y": 0,
                    "w": 320,
                    "h": 180
                },
                "sourceSize": {
                    "w": 320,
                    "h": 180
                },
                "duration": 100
            },
            {
                "filename": "trash.aseprite",
                "frame": {
                    "x": 1789,
                    "y": 0,
                    "w": 33,
                    "h": 55
                },
                "rotated": false,
                "trimmed": true,
                "spriteSourceSize": {
                    "x": 1,
                    "y": 6,
                    "w": 31,
                    "h": 53
                },
                "sourceSize": {
                    "w": 32,
                    "h": 64
                },
                "duration": 100
            },
            {
                "filename": "win_screen 0.aseprite",
                "frame": {
                    "x": 1270,
                    "y": 348,
                    "w": 418,
                    "h": 352
                },
                "rotated": false,
                "trimmed": true,
                "spriteSourceSize": {
                    "x": 107,
                    "y": 8,
                    "w": 416,
                    "h": 350
                },
                "sourceSize": {
                    "w": 640,
                    "h": 360
                },
                "duration": 100
            },
            {
                "filename": "win_screen 1.aseprite",
                "frame": {
                    "x": 1270,
                    "y": 0,
                    "w": 453,
                    "h": 348
                },
                "rotated": false,
                "trimmed": true,
                "spriteSourceSize": {
                    "x": 96,
                    "y": 7,
                    "w": 451,
                    "h": 346
                },
                "sourceSize": {
                    "w": 640,
                    "h": 360
                },
                "duration": 100
            }
        ],
        "meta": {
            "app": "http://www.aseprite.org/",
            "version": "1.3-rc6-x64",
            "image": "atlas.png",
            "format": "RGBA8888",
            "size": {
                "w": 1859,
                "h": 700
            },
            "scale": "1",
            "frameTags": [
                {
                    "name": "floppydisk",
                    "to": 0,
                    "from": 0,
                    "direction": "forward"
                },
                {
                    "name": "letter",
                    "to": 1,
                    "from": 1,
                    "direction": "forward"
                },
                {
                    "name": "main_gui",
                    "to": 2,
                    "from": 2,
                    "direction": "forward"
                },
                {
                    "name": "main_menu",
                    "to": 3,
                    "from": 3,
                    "direction": "forward"
                },
                {
                    "name": "objects",
                    "to": 4,
                    "from": 4,
                    "direction": "forward"
                },
                {
                    "name": "test-level",
                    "to": 5,
                    "from": 5,
                    "direction": "forward"
                },
                {
                    "name": "trash",
                    "to": 6,
                    "from": 6,
                    "direction": "forward"
                },
                {
                    "name": "win_screen/stage",
                    "to": 7,
                    "from": 7,
                    "direction": "forward"
                },
                {
                    "name": "win_screen/game",
                    "to": 8,
                    "from": 8,
                    "direction": "forward"
                },
                {
                    "name": "win_screen",
                    "to": 8,
                    "from": 7,
                    "direction": "forward"
                }
            ],
            "slices": [
                {
                    "name": "move_counter",
                    "color": "#0000ffff",
                    "keys": [
                        {
                            "frame": 2,
                            "bounds": {
                                "x": 70,
                                "y": 6,
                                "w": 37,
                                "h": 23
                            }
                        }
                    ],
                    "from": 2,
                    "to": 2
                },
                {
                    "name": "glitch_mode",
                    "color": "#0000ffff",
                    "keys": [
                        {
                            "frame": 3,
                            "bounds": {
                                "x": -107,
                                "y": 140,
                                "w": 207,
                                "h": 94
                            }
                        }
                    ],
                    "from": 3,
                    "to": 3
                },
                {
                    "name": "quit",
                    "color": "#0000ffff",
                    "keys": [
                        {
                            "frame": 3,
                            "bounds": {
                                "x": -99,
                                "y": 241,
                                "w": 199,
                                "h": 95
                            }
                        }
                    ],
                    "from": 3,
                    "to": 3
                },
                {
                    "name": "normal_mode",
                    "color": "#0000ffff",
                    "keys": [
                        {
                            "frame": 3,
                            "bounds": {
                                "x": -111,
                                "y": 31,
                                "w": 211,
                                "h": 107
                            }
                        }
                    ],
                    "from": 3,
                    "to": 3
                },
                {
                    "name": "wall2",
                    "color": "#0000ffff",
                    "data": "{\"type\": \"wall\"}",
                    "keys": [
                        {
                            "frame": 5,
                            "bounds": {
                                "x": 79,
                                "y": 12,
                                "w": 178,
                                "h": 36
                            }
                        }
                    ],
                    "from": 5,
                    "to": 5
                },
                {
                    "name": "wall3",
                    "color": "#0000ffff",
                    "data": "{\"type\": \"wall\"}",
                    "keys": [
                        {
                            "frame": 5,
                            "bounds": {
                                "x": 33,
                                "y": 48,
                                "w": 47,
                                "h": 96
                            }
                        }
                    ],
                    "from": 5,
                    "to": 5
                },
                {
                    "name": "wall0",
                    "color": "#0000ffff",
                    "data": "{\"type\": \"wall\"}",
                    "keys": [
                        {
                            "frame": 5,
                            "bounds": {
                                "x": 80,
                                "y": 144,
                                "w": 177,
                                "h": 35
                            }
                        }
                    ],
                    "from": 5,
                    "to": 5
                },
                {
                    "name": "wall1",
                    "color": "#0000ffff",
                    "data": "{\"type\": \"wall\"}",
                    "keys": [
                        {
                            "frame": 5,
                            "bounds": {
                                "x": 240,
                                "y": 48,
                                "w": 79,
                                "h": 97
                            }
                        }
                    ],
                    "from": 5,
                    "to": 5
                },
                {
                    "name": "block",
                    "color": "#0000ffff",
                    "data": "{\"type\": \"wall\"}",
                    "keys": [
                        {
                            "frame": 5,
                            "bounds": {
                                "x": 208,
                                "y": 112,
                                "w": 32,
                                "h": 32
                            }
                        }
                    ],
                    "from": 5,
                    "to": 5
                },
                {
                    "name": "blockagain",
                    "color": "#0000ffff",
                    "data": "{\"type\": \"wall\"}",
                    "keys": [
                        {
                            "frame": 5,
                            "bounds": {
                                "x": 144,
                                "y": 112,
                                "w": 32,
                                "h": 32
                            }
                        }
                    ],
                    "from": 5,
                    "to": 5
                },
                {
                    "name": "p1",
                    "color": "#0000ffff",
                    "data": "{\"angle\": 4.2}",
                    "keys": [
                        {
                            "frame": 7,
                            "bounds": {
                                "x": 112,
                                "y": 54,
                                "w": 31,
                                "h": 20
                            }
                        }
                    ],
                    "from": 7,
                    "to": 8
                },
                {
                    "name": "p2",
                    "color": "#0000ffff",
                    "data": "{\"angle\": 4.2}",
                    "keys": [
                        {
                            "frame": 7,
                            "bounds": {
                                "x": 113,
                                "y": 181,
                                "w": 28,
                                "h": 17
                            }
                        }
                    ],
                    "from": 7,
                    "to": 8
                },
                {
                    "name": "p3",
                    "color": "#0000ffff",
                    "data": "{\"angle\": -0.2}",
                    "keys": [
                        {
                            "frame": 7,
                            "bounds": {
                                "x": 505,
                                "y": 28,
                                "w": 14,
                                "h": 23
                            }
                        }
                    ],
                    "from": 7,
                    "to": 8
                },
                {
                    "name": "p4",
                    "color": "#0000ffff",
                    "keys": [
                        {
                            "frame": 7,
                            "bounds": {
                                "x": 493,
                                "y": 144,
                                "w": 13,
                                "h": 32
                            }
                        }
                    ],
                    "from": 7,
                    "to": 8
                },
                {
                    "name": "p5",
                    "color": "#0000ffff",
                    "data": "{\"angle\": 0.785}",
                    "keys": [
                        {
                            "frame": 7,
                            "bounds": {
                                "x": 478,
                                "y": 224,
                                "w": 19,
                                "h": 19
                            }
                        }
                    ],
                    "from": 7,
                    "to": 8
                },
                {
                    "name": "wintext",
                    "color": "#0000ffff",
                    "keys": [
                        {
                            "frame": 7,
                            "bounds": {
                                "x": -192,
                                "y": 234,
                                "w": 109,
                                "h": 54
                            }
                        },
                        {
                            "frame": 8,
                            "bounds": {
                                "x": 253,
                                "y": 162,
                                "w": 109,
                                "h": 54
                            }
                        }
                    ],
                    "from": 7,
                    "to": 8
                }
            ]
        }
    }
]]

T("atlas", function(T)
    local atlas_data = third.json.decode(atlas_json)
    local sheet = {
        getDimensions = function() return 1859, 700 end
    }
    local atlas = nw.atlas.create(sheet, atlas_data)

    T("frametags", function(T)
        for _, ref_frame_tags in ipairs(atlas_data.meta.frameTags) do
            local name = ref_frame_tags.name
            local to = ref_frame_tags.to
            local from = ref_frame_tags.from

            local t = atlas.tags[ref_frame_tags.name]
            T:assert(t, string.format("Tag doesn't exist: %s", ref_frame_tags.name))
            local msg = string.format(
                "invalid bounds: %s (from = %i, to = %i) != (from = %i, to = %i)",
                name, t.to, t.from, to, from
            )
            T:assert(t.to == to + 1 and t.from == from + 1, msg)
        end
    end)

    T("get_animation", function(T)
        for _, ref_frame_tags in ipairs(atlas_data.meta.frameTags) do
            local name = ref_frame_tags.name
            local to = ref_frame_tags.to
            local from = ref_frame_tags.from
            local animation = atlas:get_animation(name)

            T:assert(animation)
            for i, frame in ipairs(animation) do
                T:assert(frame == atlas.frames[i + from])
            end
        end
    end)

    T("frames", function(T)
        for index, ref_frame in ipairs(atlas_data.frames) do
            local frame = atlas.frames[index]
            T:assert(frame)
            local x, y, w, h = frame:get_view_port()
            T:assert(x == ref_frame.frame.x + 1)
            T:assert(y == ref_frame.frame.y + 1)
            T:assert(math.floor(frame.dt * 1000) == ref_frame.duration)
        end
    end)

    T("slice_prune_and_interpolation", function(T)
        local specific_atlas_data = {
            frames = {
                {
                    filename = "foobarname1",
                    frame = {
                        x = 10,
                        y = 10,
                        w = 102,
                        h = 62,
                    },
                    spriteSourceSize = {
                        x = 0,
                        y = 0,
                        w = 100,
                        h = 60,
                    },
                    sourceSize = {
                        w = 100,
                        h = 60
                    },
                    duration = 1000
                },
                {
                    filename = "foobarname2",
                    frame = {
                        x = 10,
                        y = 10,
                        w = 102,
                        h = 62,
                    },
                    spriteSourceSize = {
                        x = 0,
                        y = 0,
                        w = 100,
                        h = 60,
                    },
                    sourceSize = {
                        w = 100,
                        h = 60
                    },
                    duration = 1000
                },
                {
                    filename = "foobarname3",
                    frame = {
                        x = 10,
                        y = 10,
                        w = 102,
                        h = 62,
                    },
                    spriteSourceSize = {
                        x = 0,
                        y = 0,
                        w = 100,
                        h = 60,
                    },
                    sourceSize = {
                        w = 100,
                        h = 60
                    },
                    duration = 1000
                }
            },
            meta = {
                frameTags = {},
                slices = {
                    {
                        name = "foo",
                        keys = {
                            {
                                frame = 1,
                                bounds = nw.spatial(0, 0, 10, 10)
                            }
                        },
                        from = 0,
                        to = 2
                    },
                    {
                        name = "bar",
                        data = "{\"hit\": 22}",
                        keys = {
                            {
                                frame = 0,
                                bounds = nw.spatial(0, 0, 10, 10),
                            },
                            {
                                frame = 1,
                                bounds = nw.spatial(-1000, 0, 20, 20),
                            },
                            {
                                frame = 2,
                                bounds = nw.spatial(0, 0, 30, 30),
                            }
                        },
                        from = 0,
                        to = 2
                    }
                }
            }
        }

        local atlas = nw.atlas.create(sheet, specific_atlas_data)
        T:assert(#atlas.frames == 3)

        for _, frame in ipairs(atlas.frames) do
            T:assert(frame.slices.foo == nw.spatial(0, 0, 10, 10))
            T:assert(frame.slice_data.foo)
            T:assert(frame.slice_data.bar.hit == 22)
        end

        T:assert(atlas.frames[1].slices.bar == nw.spatial(0, 0, 10, 10))
        -- Not present because it is out of bounds
        T:assert(not atlas.frames[2].slices.bar)
        T:assert(atlas.frames[3].slices.bar == nw.spatial(0, 0, 30, 30))
    end)
end)