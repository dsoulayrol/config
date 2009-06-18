-- Standard awesome library
require('awful')

-- Theme handling library
require('beautiful')

-- Notification library
require('naughty')

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
--     |_ layouts
--     |_ apps
--     |_ menu
--     |_ gadgets
--     |_ widgets
--           |_ launcher
--           |_ datebox
--           |_ systray
--     |     \_ user defined widgets...
--     \_ screens
--           |_ tags
--           |_ wibox
--           \_ widgets
--                |_ layout
--                |_ prompt
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

-- Table of layouts to cover with awful.layout.inc, order matters.
conf.layouts = {
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

-- Application related preferences.
conf.apps = {}

-- This is used later as the default terminal and editor to run.
conf.apps.terminal = 'urxvt -ls'
conf.apps.editor = os.getenv('EDITOR') or 'vim'
conf.apps.editor_cmd = conf.apps.terminal .. ' -e ' .. conf.apps.editor

-- Table of clients that should be set floating. The index may be either
-- the application class or instance. The instance is useful when running
-- a console app in a terminal like (Music on Console)
--    xterm -name mocp -e mocp
conf.apps.floats = {
   -- by class
   ["MPlayer"] = true,
   ["gimp"] = true,
}

-- Applications to be moved to a pre-defined tag by class or instance.
-- Use the screen and tags indices.
conf.apps.tags = {
   ["Emacs"] = { screen = 1, tag = 2 },
   ["xchat"] = { screen = 1, tag = 3 },
   ["Iceweasel"] = { screen = 1, tag = 4 },
}

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


-- Default tag properties
local tag_names = { '1:Term', '2:Edit', '3:IRC', '4:Net', '5', '6', '7', '8:Wire', '9' }
local tag_layouts = {
   awful.layout.suit.tile,
   awful.layout.suit.max,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.tile,
   awful.layout.suit.tile,
   awful.layout.suit.tile,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.tile,
}

-- Populate screens
for s = 1, screen.count() do
   -- Each screen has its own tag table.
   conf.screens[s] = {}
   conf.screens[s].tags = {}
   conf.screens[s].widgets = {}

   -- Create 9 tags per screen.
   for tagnumber = 1, 9 do
      conf.screens[s].tags[tagnumber] = tag(tag_names[tagnumber])
      -- Add tags to screen one by one
      conf.screens[s].tags[tagnumber].screen = s
      awful.layout.set(tag_layouts[tagnumber], conf.screens[s].tags[tagnumber])
   end
   -- I'm sure you want to see at least one tag.
   conf.screens[s].tags[1].selected = true

   -- Create a promptbox for each screen
   conf.screens[s].widgets.prompt =
      widget{ type = "textbox", align = "left" }

   -- Create an imagebox widget which will contains an icon indicating which layout we're using.
   conf.screens[s].widgets.layout = widget{ type = "imagebox", align = "left" }
   conf.screens[s].widgets.layout:buttons(
      { button({ }, 1, function () awful.layout.inc(conf.layouts, 1) end),
        button({ }, 3, function () awful.layout.inc(conf.layouts, -1) end),
        button({ }, 4, function () awful.layout.inc(conf.layouts, 1) end),
        button({ }, 5, function () awful.layout.inc(conf.layouts, -1) end) })

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
       conf.screens[s].widgets.layout,
       conf.screens[s].widgets.prompt,
       conf.gadgets.cpu_icon.widget,
       conf.gadgets.cpugraph.widget,
--       w_wifi_widget,
       conf.gadgets.netgraph and conf.gadgets.netgraph.widget or nil,
       conf.gadgets.netbox and conf.gadgets.netbox.widget or nil,
       conf.gadgets.battery_icon and conf.gadgets.battery_icon.widget or nil,
       conf.gadgets.battery_box and conf.gadgets.battery_box.widget or nil,
--       w_sound_widget,
       s == 1 and conf.widgets.systray or nil,
       conf.widgets.datebox
    }

    conf.screens[s].wibox.screen = s
end

-- Keys and mouse bindings
dofile(awful.util.getdir('config') .. '/bindings.lua')

-- Hooks
dofile(awful.util.getdir('config') .. '/hooks.lua')



-- TODO move this somewhere.
-- Move the mouse out of the way.
local safeCoords = { x = 1440, y = 900 }

-- Simple function to move the mouse to the coordinates set above.
local function moveMouse(x_co, y_co)
    mouse.coords({ x=x_co, y=y_co })
end

-- Bind ''Meta4+Ctrl+m'' to move the mouse to the coordinates set above.
--   this is useful if you needed the mouse for something and now want it out of the way
--keybinding({ conf.modkey, 'Control' }, 'm',
--           function() moveMouse(safeCoords.x, safeCoords.y) end):add()

-- Optionally move the mouse when rc.lua is read (startup)
if conf.param.mouse_move_aside then
   moveMouse(safeCoords.x, safeCoords.y)
end
