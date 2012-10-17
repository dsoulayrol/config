function loadrc(name, mod)
   local success
   local result

   local path = awful.util.getdir('config') .. '/' ..
      (mod and 'lib/' or '') .. name .. '.lua'

   -- If the module is already loaded, don't load it again
   if mod and package.loaded[mod] then return package.loaded[mod] end

   -- Execute the RC/module file
   success, result = pcall(function() return dofile(path) end)
   if not success then
      naughty.notify({ title = 'Error while loading an RC file',
                       text = 'When loading `' .. name ..
                          '`, got the following error:\n' .. result,
                       preset = naughty.config.presets.critical
                    })
      return print('E: error loading RC file `' .. name .. '`: ' .. result)
   end

   -- Is it a module?
   if mod then
      return package.loaded[mod]
   end

   return result
end



-- Set locale.
os.setlocale(os.getenv('LANG'))

-- Standard awesome library
require('awful')
require('awful.autofocus')

-- Theme handling library
require('beautiful')
beautiful.init(awful.util.getdir('config') .. '/theme.lua')

-- Notification library
require('naughty')

-- Flaw
require('flaw')

-- Load Debian menu entries
require("debian.menu")

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
--           |_ systray
--           |_ prompt
--     |     \_ user defined widgets...
--     \_ screens
--           |_ tags
--           |_ wibox
--           \_ widgets
--                |_ layout
--                \_ taglist

conf = {}
conf.param = {}
conf.bindings = { global = {}, client = {} }
conf.layouts = {}
conf.screens = {}
conf.gadgets = {}
conf.widgets = {}

-- Default parameters
conf.modkey = 'Mod4'
conf.param.sweep_on_start = false
conf.param.sweep_coords = { x = 0, y = 0 }

-- Load local parameters
loadrc('local')

-- Shifty configuration - Dynamic tagging library
require("shifty_configuration")
conf.layouts = shifty.config.layouts

-- Application related preferences.
conf.apps = {}

-- This is used later as the default terminal and editor to run.
conf.apps.terminal = 'urxvt -ls'
conf.apps.calendar = 'urxvt -rv -T agenda -e bash --noprofile --norc -c "remind ~/.config/remind/all.rem && read -s -n1"'
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
loadrc('gadgets')

-- Populate screens
for s = 1, screen.count() do
   -- Each screen has its own tag table.
   conf.screens[s] = {}
   conf.screens[s].tags = {}
   conf.screens[s].widgets = {}

   -- Create an imagebox widget which will contains an icon indicating which layout we're using.
   conf.screens[s].widgets.layout = awful.widget.layoutbox(s)
   conf.screens[s].widgets.layout:buttons(
      awful.util.table.join(
         awful.button({ }, 1, function () awful.layout.inc(conf.layouts, 1) end),
         awful.button({ }, 3, function () awful.layout.inc(conf.layouts, -1) end),
         awful.button({ }, 4, function () awful.layout.inc(conf.layouts, 1) end),
         awful.button({ }, 5, function () awful.layout.inc(conf.layouts, -1) end)))

   -- Create a taglist widget
   conf.screens[s].widgets.taglist =
      awful.widget.taglist(
      s, awful.widget.taglist.label.all,
      awful.util.table.join(
         awful.button({ }, 1, awful.tag.viewonly),
         awful.button({ conf.modkey }, 1, awful.client.movetotag),
         awful.button({ }, 3, function (tag) tag.selected = not tag.selected end),
         awful.button({ conf.modkey }, 3, awful.client.toggletag),
         awful.button({ }, 4, awful.tag.viewnext),
         awful.button({ }, 5, awful.tag.viewprev)))

    -- Create the wibox
    conf.screens[s].wibox =
       awful.wibox({ position = "top", screen = s,
                     fg = beautiful.fg_normal, bg = beautiful.bg_normal })

    -- Add widgets to the wibox - order matters
    conf.screens[s].wibox.widgets = {
       {
          conf.widgets.launcher,
          conf.screens[s].widgets.taglist,
          conf.screens[s].widgets.layout,
          conf.gadgets.title.widget,
          layout = awful.widget.layout.horizontal.leftright
       },

       conf.gadgets.calendar.widget,
       conf.gadgets.kbd.widget,
       conf.gadgets.battery_box and conf.gadgets.battery_box.widget or nil,
       conf.gadgets.battery_icon and conf.gadgets.battery_icon.widget or nil,
       conf.gadgets.alsa_lbl.widget,
       s == 1 and conf.widgets.systray or nil,
       s == 1 and conf.gadgets.net_graph.widget or nil,
       conf.gadgets.wifi_lbl and conf.gadgets.wifi_lbl.widget or nil,
       s == 1 and conf.gadgets.net_icon.widget or nil,
       s == 1 and conf.gadgets.cpu_graph.widget or nil,
       s == 1 and conf.gadgets.cpu_icon.widget or nil,
       layout = awful.widget.layout.horizontal.rightleft
    }
end

-- shifty.taglist accepts the default configuration format only: a
-- table of taglists, indexed by the screen.
shifty.taglist = { conf.screens[1].widgets.taglist }

-- Keys and mouse bindings
loadrc('bindings')

-- Hooks
loadrc('hooks')

-- Load local modules
-- ...

if conf.param.sweep_on_start then
   mouse.coords(conf.param.sweep_coords)
end

-- Now that everything is loaded, set bindings.
root.keys(conf.bindings.global)
shifty.config.globalkeys = conf.bindings.global
shifty.config.clientkeys = conf.bindings.client

flaw.check_modules()
