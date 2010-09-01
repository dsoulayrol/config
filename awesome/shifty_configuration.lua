-- Dynamic tagging library
require('shifty')

-- Shifty configuration.

-- If set to true (default) shifty will attempt to guess new tag name
-- from client's class. This has effect only when a client is
-- unmatched and being opened when there's no tags or current tag is
-- solitary or exclusive.
shifty.config.guess_name = true

-- If set to true (default) shifty will check first character of a tag
-- name for being a number and set tag's position according to
-- that. Providing position explicitly overrides this.
shifty.config.guess_position = true

-- If set to true (default) shifty will keep track of tag's taglist
-- index and if closed reopen the tag at the same place. Specifying
-- position, index or rel_index overrides this.
shifty.config.remember_index = true

-- If set (to a table of layout functions), enables setting layouts by
-- short name.
shifty.config.layouts = {
   awful.layout.suit.tile,
   awful.layout.suit.tile.left,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.tile.top,
   awful.layout.suit.fair,
   awful.layout.suit.fair.horizontal,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
   awful.layout.suit.magnifier,
   awful.layout.suit.floating
}

shifty.config.tags = {
   ["1:Term"] = { init = true, screen = 1, mwfact = 0.60,                     },
   ["2:IRC"] = { spawn = "xchat", layout = "tilebottom",                      },
   ["3:Net"] = { spawn = "iceweasel", layout = "tilebottom",                  },
   ["gimp"] = { spawn = "gimp", exclusive = true,
                layout = "max", icon_only = true,
                icon = "/usr/share/icons/hicolor/16x16/apps/gimp.png",        },
   ["wire"] = { layout = "tilebottom",                                        },
}

shifty.config.apps = {
   { match = { "htop", "Wicd", "jackctl"       }, tag = "1:Term",             },
   { match = {"xchat"                          }, tag = "2:IRC",              },
   { match = {"Iceweasel.*", "Firefox.*"       }, tag = "3:Net",              },
   { match = {"wireshark",                     }, tag = "wire"                },

   -- gargoyle
   { match = { "git" }, tag = "IF", fullscreen = true                         },

   -- gimp
   { match = { "Gimp" }, tag = "gimp",                                        },
   { match = { "gimp.toolbox", "gimp%-image%-window" },
     slave = true, float = true,                                              },

   -- floats
   { match = { "MPlayer" }, float = true, ontop = true                        },
   { match = { "Wine" }, float = true                                         },

   -- intrusives
   { match = { "urxvt", "urxvt-unicode" },
     honorsizehints = true, intrusive = true,                                 },

   -- bindings
   { match = { "" }, honorsizehints = false, buttons = awful.util.table.join(
        awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
        awful.button({ conf.modkey }, 1, function (c) awful.mouse.client.move() end),
        awful.button({ conf.modkey }, 3, awful.mouse.client.resize )), }
}

shifty.config.defaults = {
   layout = awful.layout.suit.tile,
   ncol = 1,
--   mwfact = 0.60,
}

shifty.init()
