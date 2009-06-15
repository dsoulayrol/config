-- All mouse and key bindings related stuff.

-- Grab environment
local awful = require('awful')
-- local revelation = require('revelation')

if conf == nil then
   -- should trace something here... not sure where traces can be found...
   -- perhaps should bind minimal default keys (restart).
end

-- Private variables
local tag_keys = {
   '#10', '#11', '#12', '#13', '#14', '#15', '#16', '#17', '#18'
--   "agrave", "ampersand", "eacute", "quotedbl", "apostrophe",
--   "parenleft", "minus", "egrave", "underscore", "ccedilla"
}

-- Mouse bindings
root.buttons(
   awful.util.table.join(
      awful.button({ }, 3, function () conf.menu:toggle() end),
      awful.button({ }, 4, awful.tag.viewnext),
      awful.button({ }, 5, awful.tag.viewprev)
))

conf.bindings.global = awful.util.table.join(
   awful.key({ conf.modkey,           }, "Left",   awful.tag.viewprev       ),
   awful.key({ conf.modkey,           }, "Right",  awful.tag.viewnext       ),
   awful.key({ conf.modkey,           }, "Escape", awful.tag.history.restore),

   awful.key({ conf.modkey,           }, "j",
             function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
             end),
   awful.key({ conf.modkey,           }, "k",
             function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
             end),

   -- Layout manipulation
   awful.key({ conf.modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1) end),
   awful.key({ conf.modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1) end),
   awful.key({ conf.modkey, "Control" }, "j", function () awful.screen.focus( 1)       end),
   awful.key({ conf.modkey, "Control" }, "k", function () awful.screen.focus(-1)       end),
   awful.key({ conf.modkey,           }, "u", awful.client.urgent.jumpto),
   awful.key({ conf.modkey,           }, "Tab",
             function ()
                awful.client.focus.history.previous()
                if client.focus then
                   client.focus:raise()
                end
             end),

    -- Standard program
   awful.key({ conf.modkey,           }, "Return", function () awful.util.spawn(conf.apps.terminal) end),
   awful.key({ conf.modkey, "Control" }, "r", awesome.restart),
   awful.key({ conf.modkey, "Shift"   }, "q", awesome.quit),

   awful.key({ conf.modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
   awful.key({ conf.modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
   awful.key({ conf.modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
   awful.key({ conf.modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
   awful.key({ conf.modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
   awful.key({ conf.modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
   awful.key({ conf.modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
   awful.key({ conf.modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

   -- Prompt
--   awful.key({ conf.modkey            }, "F1"   , function () conf.screens[mouse.screen].widgets.prompt:run() end),
   awful.key({ conf.modkey }, "F1",
             function ()
                awful.prompt.run({ prompt = "Run: " },
                                 conf.screens[mouse.screen].widgets.prompt,
                                 awful.util.spawn, awful.completion.bash,
                                 awful.util.getdir("cache") .. "/history")
             end),

   awful.key({ conf.modkey }, "F4",
        function ()
           awful.prompt.run({ prompt = "Run Lua code: " },
                            conf.screens[mouse.screen].widgets.prompt,
                            awful.util.eval, nil,
                            awful.util.getdir("cache") .. "/history_eval")
        end),

   -- Special keys
   awful.key({ }, "XF86AudioMute", function () awful.util.spawn('amixer -c 0 set Master toggle') end),
   awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn('amixset +') end),
   awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn('amixset -') end),
   awful.key({ }, "XF86AudioPlay", function () awful.util.spawn('mpc toggle') end),
   awful.key({ }, "XF86AudioNext", function () awful.util.spawn('mpc next') end),
   awful.key({ }, "XF86AudioStop", function () awful.util.spawn('mpc stop ') end),
   awful.key({ }, "XF86AudioPrev", function () awful.util.spawn('mpc prev ') end),
-- awful.key({ }, "XF86Sleep", function () awful.util.spawn('sudo pm-suspend --quirk-dpms-on --quirk-vbestate-restore --quirk-vbemode-restore') end),
-- awful.key({ }, "XF86HomePage", function () awful.util.spawn('sudo cpufreq-set -g ondemand') end),
-- awful.key({ }, "XF86Start", function () awful.util.spawn('sudo cpufreq-set -g powersave') end),
   awful.key({ }, "XF86WWW", function () awful.util.spawn('firefox') end),
   awful.key({ }, "XF86Mail", function () awful.util.spawn('urxvt -e mutt') end),
   awful.key({ }, "XF86Messenger", function () awful.util.spawn('urxvt -e irssi') end)
)

-- Client awful tagging: this is useful to tag some clients and then
-- do stuff like move to tag on them
conf.bindings.client = awful.util.table.join(
   awful.key({ conf.modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
   awful.key({ conf.modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
   awful.key({ conf.modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
   awful.key({ conf.modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
   awful.key({ conf.modkey,           }, "o",      awful.client.movetoscreen                        ),
   awful.key({ conf.modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
   awful.key({ conf.modkey }, "t", awful.client.togglemarked),
   awful.key({ conf.modkey,}, "m",
             function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c.maximized_vertical   = not c.maximized_vertical
             end)
)

-- Tags access
-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#conf.screens[s].tags, keynumber))
end

for i = 1, keynumber do
conf.bindings.global = awful.util.table.join(conf.bindings.global,
                                             awful.key({ conf.modkey }, tag_keys[i],
                                                       function ()
                                                          local screen = mouse.screen
                                                          if conf.screens[screen].tags[i] then
                                                             awful.tag.viewonly(conf.screens[screen].tags[i])
                                                          end
                                                       end),
                                             awful.key({ conf.modkey, "Control" }, tag_keys[i],
                                                       function ()
                                                          local screen = mouse.screen
                                                          if conf.screens[screen].tags[i] then
                                                             conf.screens[screen].tags[i].selected = not conf.screens[screen].tags[i].selected
                                                          end
                                                       end),
                                             awful.key({ conf.modkey, "Shift" }, tag_keys[i],
                                                       function ()
                                                          if client.focus and conf.screens[client.focus.screen].tags[i] then
                                                             awful.client.movetotag(conf.screens[client.focus.screen].tags[i])
                                                          end
                                                       end),
                                             awful.key({ conf.modkey, "Control", "Shift" }, tag_keys[i],
                                                       function ()
                                                          if client.focus and conf.screens[client.focus.screen].tags[i] then
                                                             awful.client.toggletag(conf.screens[client.focus.screen].tags[i])
                                                          end
                                                       end),
                                             awful.key({ conf.modkey, "Shift" }, "F" .. i,
                                                       function ()
                                                          local screen = mouse.screen
                                                          if conf.screens[screen].tags[i] then
                                                             for k, c in pairs(awful.client.getmarked()) do
                                                                awful.client.movetotag(conf.screens[screen].tags[i], c)
                                                             end
                                                          end
                                                       end))
end

-- Set keys
root.keys(conf.bindings.global)


-- Client manipulation
-- keybinding({ conf.modkey }, "F2", revelation.revelation):add()
