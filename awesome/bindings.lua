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

-- Local functions
function _get_tag_info()
   local t = awful.tag.selected()
   local v = "<span font_desc=\"Verdana Bold 20\">" .. t.name .. "</span>\n"

   v = v .. tostring(t) .. "\n\n"
   v = v .. "clients: " .. #t:clients() .. "\n\n"

   local i = 1
   for op, val in pairs(awful.tag.getdata(t)) do
      if op == "layout" then val = awful.layout.getname(val) end
      if op == "keys" then val = '#' .. #val end
      v = v .. string.format("%2s: %-12s = %s\n", i, op, tostring(val))
      i = i + 1
   end

   naughty.notify{ text = v:sub(1,#v-1), timeout = 0, margin = 10 }
end

function _get_client_info()
   local v = ""

   -- object
   local c = client.focus
   v = v .. tostring(c)

   -- geometry
   local cc = c:geometry()
   local signx = (cc.x > 0 and "+") or ""
   local signy = (cc.y > 0 and "+") or ""
   v = v .. " @ " .. cc.width .. 'x' .. cc.height .. signx .. cc.x .. signy .. cc.y .. "\n\n"

   local inf = {
      "name", "icon_name", "type", "class", "role", "instance", "pid",
      "icon_name", "skip_taskbar", "id", "group_id", "leader_id", "machine",
      "screen", "hide", "minimize", "size_hints_honor", "titlebar", "urgent",
      "focus", "opacity", "ontop", "above", "below", "fullscreen", "transient_for"
   }

   for i = 1, #inf do
      v = v .. string.format("%2s: %-16s = %s\n", i, inf[i], tostring(c[inf[i]]))
   end

   naughty.notify{ text = v:sub(1,#v-1), timeout = 0, margin = 10 }
end

-- Mouse bindings
root.buttons(
   awful.util.table.join(
      awful.button({ }, 3, function () conf.menu:toggle() end),
      awful.button({ }, 4, awful.tag.viewnext),
      awful.button({ }, 5, awful.tag.viewprev)
))

conf.bindings.global = awful.util.table.join(

   -- tags
   awful.key({ conf.modkey,           }, "Left",   awful.tag.viewprev       ),
   awful.key({ conf.modkey,           }, "Right",  awful.tag.viewnext       ),
   awful.key({ conf.modkey,           }, "Escape", awful.tag.history.restore),

   -- clients
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

   -- layout
   awful.key({ conf.modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
   awful.key({ conf.modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
   awful.key({ conf.modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
   awful.key({ conf.modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
   awful.key({ conf.modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
   awful.key({ conf.modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
   awful.key({ conf.modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
   awful.key({ conf.modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    -- standard program
   awful.key({ conf.modkey,           }, "Return", function () awful.util.spawn(conf.apps.terminal) end),
   awful.key({ conf.modkey, "Control" }, "r", awesome.restart),
   awful.key({ conf.modkey, "Shift"   }, "q", awesome.quit),

   -- shifty dedicated bindings
   awful.key({ conf.modkey,           }, "t", function() shifty.add({ rel_index = 1 }) end, nil, "new tag"),
   awful.key({ conf.modkey, "Control" }, "t", function() shifty.add({ rel_index = 1, nopopup = true }) end, nil, "new tag in bg"),
   awful.key({ conf.modkey,           }, "r", shifty.rename, nil, "tag rename"),
   awful.key({ conf.modkey,           }, "w", shifty.del, nil, "tag delete"),

   -- diagnostic
   awful.key({ conf.modkey,           }, 'i', _get_tag_info, nil, "tag info"),

   -- Prompt
   awful.key({ conf.modkey }, "F1",
             function ()
                awful.prompt.run({ prompt = "Run: " },
                                 conf.screens[mouse.screen].widgets.prompt,
                                 awful.util.spawn, awful.completion.bash,
                                 awful.util.getdir("cache") .. "/history")
             end),
   awful.key({ conf.modkey }, "F2",
             function ()
                awful.prompt.run({ prompt = "Web search: " },
                                 conf.screens[mouse.screen].widgets.prompt,
                                 function (command)
                                    awful.util.spawn("firefox -new-tab 'http://yubnub.org/parser/parse?command=" .. command .. "'", false)
                                    -- TODO: switch to the tag holding
                                    -- the iceweasel instance, with
                                    -- shifty configuration ?
                                 end)
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
             end),

   -- diagnostic
   awful.key({ conf.modkey, "Shift"   }, 'i', _get_client_info, nil, "client info")
)

for i = 1, 9 do
conf.bindings.global = awful.util.table.join(conf.bindings.global,
   awful.key({ conf.modkey }, tag_keys[i],
             function ()
                local t = shifty.getpos(i)
                if t then awful.tag.viewonly(t) end
             end),
   awful.key({ conf.modkey, "Control" }, tag_keys[i],
             function ()
                local t = shifty.getpos(i)
                if t then t.selected = not t.selected end
             end),
   awful.key({ conf.modkey, "Shift" }, tag_keys[i],
             function ()
                local t = shifty.getpos(i)
                if client.focus and t then
                   awful.client.movetotag(t)
                   awful.tag.viewonly(t)
                end
             end),
   awful.key({ conf.modkey, "Control", "Shift" }, tag_keys[i],
             function ()
                local t = shifty.getpos(i)
                if client.focus and t then awful.client.toggletag(t) end
             end))
end

-- Set keys
root.keys(conf.bindings.global)
shifty.config.globalkeys = conf.bindings.global
shifty.config.clientkeys = conf.bindings.client


-- Client manipulation
-- keybinding({ conf.modkey }, "F2", revelation.revelation):add()
