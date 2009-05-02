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
   '#10', '#11', '#12', '#13', '#14', '#15', '#16', '#17', '#18' }

-- Mouse bindings
root.buttons({
                button({ }, 3, function () conf.menu:toggle() end),
                button({ }, 4, awful.tag.viewnext),
                button({ }, 5, awful.tag.viewprev)
             })

conf.bindings.global =
{
    key({ conf.modkey,           }, "Left",   awful.tag.viewprev       ),
    key({ conf.modkey,           }, "Right",  awful.tag.viewnext       ),
    key({ conf.modkey,           }, "Escape", awful.tag.history.restore),

    key({ conf.modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    key({ conf.modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- Layout manipulation
    key({ conf.modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1) end),
    key({ conf.modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1) end),
    key({ conf.modkey, "Control" }, "j", function () awful.screen.focus( 1)       end),
    key({ conf.modkey, "Control" }, "k", function () awful.screen.focus(-1)       end),
    key({ conf.modkey,           }, "u", awful.client.urgent.jumpto),
    key({ conf.modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    key({ conf.modkey,           }, "Return", function () awful.util.spawn(conf.apps.terminal) end),
    key({ conf.modkey, "Control" }, "r", awesome.restart),
    key({ conf.modkey, "Shift"   }, "q", awesome.quit),

    key({ conf.modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    key({ conf.modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    key({ conf.modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    key({ conf.modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    key({ conf.modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    key({ conf.modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    key({ conf.modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    key({ conf.modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- Prompt
    key({ conf.modkey }, "F1",
        function ()
            awful.prompt.run({ prompt = "Run: " },
                             conf.screens[mouse.screen].widgets.prompt,
                             awful.util.spawn, awful.completion.bash,
                             awful.util.getdir("cache") .. "/history")
        end),

    key({ conf.modkey }, "F4",
        function ()
           awful.prompt.run({ prompt = "Run Lua code: " },
                            conf.screens[mouse.screen].widgets.prompt,
                            awful.util.eval, awful.prompt.bash,
                            awful.util.getdir("cache") .. "/history_eval")
        end),

    -- Special keys
    key({none               }, "XF86AudioMute", function () awful.util.spawn('amixer -c 0 set Master toggle') end),
    key({none               }, "XF86AudioRaiseVolume", function () awful.util.spawn('amixset +') end),
    key({none               }, "XF86AudioLowerVolume", function () awful.util.spawn('amixset -') end),
    key({none               }, "XF86AudioPlay", function () awful.util.spawn('mpc toggle') end),
    key({none               }, "XF86AudioNext", function () awful.util.spawn('mpc next') end),
    key({none               }, "XF86AudioStop", function () awful.util.spawn('mpc stop ') end),
    key({none               }, "XF86AudioPrev", function () awful.util.spawn('mpc prev ') end),
--  key({none               }, "XF86Sleep", function () awful.util.spawn('sudo pm-suspend --quirk-dpms-on --quirk-vbestate-restore --quirk-vbemode-restore') end),
--  key({none               }, "XF86HomePage", function () awful.util.spawn('sudo cpufreq-set -g ondemand') end),
--  key({none               }, "XF86Start", function () awful.util.spawn('sudo cpufreq-set -g powersave') end),
    key({none               }, "XF86WWW", function () awful.util.spawn('firefox') end),
    key({none               }, "XF86Mail", function () awful.util.spawn('urxvt -e mutt') end),
    key({none               }, "XF86Messenger", function () awful.util.spawn('urxvt -e irssi') end),
}

-- Client awful tagging: this is useful to tag some clients and then
-- do stuff like move to tag on them
conf.bindings.client =
{
    key({ conf.modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    key({ conf.modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    key({ conf.modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    key({ conf.modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    key({ conf.modkey,           }, "o",      awful.client.movetoscreen                        ),
    key({ conf.modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    key({ conf.modkey }, "t", awful.client.togglemarked),
    key({ conf.modkey,}, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end),
}

-- Tags access
-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#conf.screens[s].tags, keynumber))
end

for i = 1, keynumber do
   table.insert(conf.bindings.global,
                key({ conf.modkey }, tag_keys[i],
                    function ()
                       local screen = mouse.screen
                       if conf.screens[screen].tags[i] then
                          awful.tag.viewonly(conf.screens[screen].tags[i])
                       end
                    end))
   table.insert(conf.bindings.global,
                key({ conf.modkey, "Control" }, tag_keys[i],
                    function ()
                       local screen = mouse.screen
                       if conf.screens[screen].tags[i] then
                          conf.screens[screen].tags[i].selected = not conf.screens[screen].tags[i].selected
                       end
                    end))
   table.insert(conf.bindings.global,
                key({ conf.modkey, "Shift" }, tag_keys[i],
                    function ()
                       if client.focus and conf.screens[client.focus.screen].tags[i] then
                          awful.client.movetotag(conf.screens[client.focus.screen].tags[i])
                       end
                    end))
   table.insert(conf.bindings.global,
                key({ conf.modkey, "Control", "Shift" }, tag_keys[i],
                    function ()
                       if client.focus and conf.screens[client.focus.screen].tags[i] then
                          awful.client.toggletag(conf.screens[client.focus.screen].tags[i])
                       end
                    end))
end

for i = 1, keynumber do
   table.insert(conf.bindings.global, key({ conf.modkey, "Shift" }, "F" .. i,
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
