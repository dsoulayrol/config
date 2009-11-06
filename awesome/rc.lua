-- Standard awesome library
require('awful')

-- Theme handling library
require('beautiful')

-- Notification library
require('naughty')

-- Dynamic tagging library
require('shifty')

-- Flaw
require('flaw')

-- Load Debian menu entries
require("debian.menu")

-- Load theme
beautiful.init(awful.util.getdir('config') .. '/theme.lua')

-- Variable definitions

-- The whole configuration table.
--
--   conf
--     |_ modkey
--     |_ bindings
--     |     |_ global
--     |     \_ client
--     |_ apps
--     |_ menu
--     |_ gadgets
--     |_ widgets
--           |_ launcher
--           |_ datebox
--           |_ systray
--           |_ prompt
--     |     \_ user defined widgets...
--     \_ screens
--           |_ tags
--           |_ wibox
--           \_ widgets
--                |_ layout
--                |_ window title
--                \_ taglist

conf = {}
conf.param = {}
conf.bindings = { global = {}, client = {} }
conf.screens = {}
conf.gadgets = {}
conf.widgets = {}

-- Load local parameters
dofile(awful.util.getdir('config') .. '/local.lua')

-- Default modkey.
conf.modkey = 'Mod4'

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
   ["2:Edit"] = { spawn = "emacs", layout = "max", exclusive = true,          },
   ["3:IRC"] = { spawn = "xchat", layout = "tilebottom",                      },
   ["4:Net"] = { spawn = "iceweasel", layout = "tilebottom",                  },
   ["gimp"] = { spawn = "gimp", exclusive = true,
                layout = "max", icon_only = true,
                icon = "/usr/share/icons/hicolor/16x16/apps/gimp.png",        },
   ["wire"] = { layout = "tilebottom",                                        },
}

shifty.config.apps = {
   { match = { "htop", "Wicd", "jackctl"       }, tag = "1:Term",             },
   { match = {"emacs", "emacs-snapshot"        }, tag = "2:Edit",             },
   { match = {"xchat"                          }, tag = "3:IRC",              },
   { match = {"Iceweasel.*", "Firefox.*"       }, tag = "4:Net",              },
   { match = {"wireshark",                     }, tag = "wire"                },

   -- gimp
   { match = { "Gimp" }, tag = "gimp",                                        },
   { match = { "gimp.toolbox", "gimp%-image%-window" },
     slave = true, float = true,                                              },

   -- floats
   { match = { "MPlayer" }, float = true,                                     },

   -- intrusives
   { match = { "urxvt", "urxvt-unicode" },
     honorsizehints = true, intrusive = true,                                 },

   -- bindings
   { match = { "" }, honorsizehints = false, buttons = {
        button({ }, 1, function (c) client.focus = c; c:raise() end),
        button({ conf.modkey }, 1, function (c) awful.mouse.client.move() end),
        button({ conf.modkey }, 3, awful.mouse.client.resize ) }              },
}

shifty.config.defaults = {
   layout = awful.layout.suit.tile,
   ncol = 1,
--   mwfact = 0.60,
}

shifty.init()

-- Application related preferences.
conf.apps = {}

-- This is used later as the default terminal and editor to run.
conf.apps.terminal = 'urxvt -ls'
conf.apps.editor = os.getenv('EDITOR') or 'vim'
conf.apps.editor_cmd = conf.apps.terminal .. ' -e ' .. conf.apps.editor

-- Menu
local my_menu = {
   { 'manual', conf.apps.terminal .. ' -e man awesome' },
   { 'edit config', conf.apps.editor_cmd .. ' ' .. awful.util.getdir('config') .. '/rc.lua' },
   { 'restart', awesome.restart },
   { 'quit', awesome.quit }
}

conf.menu = awful.menu.new(
   {
      items = { { 'awesome', my_menu, beautiful.awesome_icon },
                { 'open terminal', conf.apps.terminal },
                { "Debian", debian.menu.Debian_menu.Debian }
             }
   })

-- Create a launcher widget
conf.widgets.launcher =
   awful.widget.launcher{ image = image(beautiful.awesome_icon), menu = conf.menu }

-- Common widgets
dofile(awful.util.getdir('config') .. '/gadgets.lua')

-- Populate screens
for s = 1, screen.count() do
   -- Each screen has its own tag table.
   conf.screens[s] = {}
   conf.screens[s].tags = {}
   conf.screens[s].widgets = {}

   -- Create an imagebox widget which will contains an icon indicating which layout we're using.
   conf.screens[s].widgets.layout = widget{ type = "imagebox", align = "right" }
   conf.screens[s].widgets.layout:buttons(
      { button({ }, 1, function () awful.layout.inc(shifty.config.layouts, 1) end),
        button({ }, 3, function () awful.layout.inc(shifty.config.layouts, -1) end),
        button({ }, 4, function () awful.layout.inc(shifty.config.layouts, 1) end),
        button({ }, 5, function () awful.layout.inc(shifty.config.layouts, -1) end) })

   -- Create a widget for the active window title.
   conf.screens[s].widgets.wtitle = widget({ type = "textbox", align = "left" })
   conf.screens[s].widgets.wtitle.text =
      "<b><small> " .. awesome.release .. " </small></b>"

   -- Create a taglist widget
   conf.screens[s].widgets.taglist =
      awful.widget.taglist.new(
      s, awful.widget.taglist.label.all, {
         button({ }, 1, awful.tag.viewonly),
         button({ conf.modkey }, 1, awful.client.movetotag),
         button({ }, 3, function (tag) tag.selected = not tag.selected end),
         button({ conf.modkey }, 3, awful.client.toggletag),
         button({ }, 4, awful.tag.viewnext),
         button({ }, 5, awful.tag.viewprev) }
    )

    -- Create the wibox
    conf.screens[s].wibox =
       wibox({ position = "top", fg = beautiful.fg_normal, bg = beautiful.bg_normal })

    -- Add widgets to the wibox - order matters
    conf.screens[s].wibox.widgets = {
       conf.widgets.launcher,
       conf.screens[s].widgets.taglist,
       conf.screens[s].widgets.wtitle,
       conf.gadgets.cpu_icon.widget,
       conf.gadgets.cpugraph.widget,
--       w_wifi_widget,
       conf.gadgets.netgraph and conf.gadgets.netgraph.widget or nil,
       conf.gadgets.netbox and conf.gadgets.netbox.widget or nil,
       conf.gadgets.battery_icon and conf.gadgets.battery_icon.widget or nil,
       conf.gadgets.battery_box and conf.gadgets.battery_box.widget or nil,
--       w_sound_widget,
       conf.widgets.datebox,
       s == 1 and conf.widgets.systray or nil,
       conf.screens[s].widgets.layout
    }

    conf.screens[s].wibox.screen = s
end

-- shifty.taglist accepts the default configuration format only: a
-- table of taglists, indexed by the screen.
shifty.taglist = { conf.screens[1].widgets.taglist }


-- Keys and mouse bindings
dofile(awful.util.getdir('config') .. '/bindings.lua')

-- Hooks
dofile(awful.util.getdir('config') .. '/hooks.lua')

-- Load local modules
-- These modules can rely on the full configuration, so they must be
-- loaded late.
require('calendar')
require('sweep_mouse')
