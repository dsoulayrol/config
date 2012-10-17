-- All mouse and key bindings related stuff.

-- Grab environment
local awful = require('awful')
local beautiful = require('beautiful')
local keydoc = loadrc('keydoc', 'vbe/keydoc')
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
      "skip_taskbar", "id", "group_id", "leader_id", "machine",
      "screen", "hide", "minimize", "size_hints_honor", "titlebar", "urgent",
      "focus", "opacity", "ontop", "above", "below", "fullscreen", "transient_for"
   }

   for i = 1, #inf do
      v = v .. string.format("%2s: %-16s = %s\n", i, inf[i], tostring(c[inf[i]]))
   end

   naughty.notify{ text = v:sub(1,#v-1), timeout = 0, margin = 10 }
end

function _prompt(cue, exe_cb, completion_cb, cache)
   local wibox = awful.wibox(
      { position = "bottom", fg = beautiful.fg_normal, bg = beautiful.bg_normal })
   wibox.widgets = { conf.widgets.prompt }
   -- wibox.attach(mouse.screen)
   wibox.screen = mouse.screen
   awful.prompt.run(
      { prompt = cue }, conf.widgets.prompt, exe_cb, completion_cb, cache, 50,
      function() wibox.screen = nil end
   )
end

function tag_move(t, scr)
   local ts = t or awful.tag.selected()
   local screen_target = scr or awful.util.cycle(screen.count(), ts.screen + 1)

   shifty.set(ts, {screen = screen_target})
end

function tag_to_screen(t, scr)
   local ts = t or awful.tag.selected()
   local screen_origin = ts.screen
   local screen_target = scr or awful.util.cycle(screen.count(), ts.screen + 1)

   awful.tag.history.restore(ts.screen,1)
   tag_move(ts, screen_target)

   -- never waste a screen
   if #(screen[screen_origin]:tags()) == 0 then
      for _, tag in pairs(screen[screen_target]:tags()) do
         if not tag.selected then
            tag_move(tag, screen_origin)
            tag.selected = true
            break
         end
      end
   end

   awful.tag.viewonly(ts)
   mouse.screen = ts.screen
   if #ts:clients() > 0 then
      local c = ts:clients()[1]
      client.focus = c
   end
end

-- Mouse bindings
root.buttons(
   awful.util.table.join(
      awful.button({ }, 3, function () conf.menu:toggle() end),
      awful.button({ }, 4, awful.tag.viewnext),
      awful.button({ }, 5, awful.tag.viewprev)
))

-- Global bindings
conf.bindings.global = awful.util.table.join(
   conf.bindings.global,

   keydoc.group('Focus'),

   -- tags
   awful.key({ conf.modkey, }, "Left", awful.tag.viewprev),
   awful.key({ conf.modkey, }, "Right", awful.tag.viewnext),
   awful.key({ conf.modkey, }, "Escape", awful.tag.history.restore),

   -- clients
   awful.key({ conf.modkey, }, "j",
             function ()
                awful.client.focus.byidx( 1)
                if client.focus then client.focus:raise() end
             end,
             'Focus next window'),
   awful.key({ conf.modkey, }, "k",
             function ()
                awful.client.focus.byidx(-1)
                if client.focus then client.focus:raise() end
             end,
             'Focus previous window'),
   awful.key({ conf.modkey, "Shift" }, "j",
             function () awful.client.swap.byidx(  1) end,
             'Swap with next window'),
   awful.key({ conf.modkey, "Shift" }, "k",
             function () awful.client.swap.byidx( -1) end,
             'Swap with previous window'),
   awful.key({ conf.modkey, "Control" }, "j",
             function () awful.screen.focus_relative( 1) end),
   awful.key({ conf.modkey, "Control" }, "k",
             function () awful.screen.focus_relative(-1) end),
   awful.key({ conf.modkey, }, "u", awful.client.urgent.jumpto),
   awful.key({ conf.modkey, }, "Tab",
             function ()
                awful.client.focus.history.previous()
                if client.focus then
                   client.focus:raise()
                end
             end),
   awful.key({ conf.modkey, }, "a",
             function ()
                awful.menu.clients({ width= 400 }, { keygrabber=true })
             end),

   -- layout
   keydoc.group('Layout'),
   awful.key({ conf.modkey, }, "l", function () awful.tag.incmwfact( 0.05) end,
             'Increase master width factor'),
   awful.key({ conf.modkey, }, "h", function () awful.tag.incmwfact(-0.05) end,
             'Decrease master width factor'),
   awful.key({ conf.modkey, "Shift" }, "h", function () awful.tag.incnmaster( 1) end,
             'Increase number of masters'),
   awful.key({ conf.modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1) end,
             'Decrease number of masters'),
   awful.key({ conf.modkey, "Control" }, "h", function () awful.tag.incncol( 1) end,
             'Increase number of columns'),
   awful.key({ conf.modkey, "Control" }, "l", function () awful.tag.incncol(-1) end,
             'Decrease number of columns'),
   awful.key({ conf.modkey, }, "space", function () awful.layout.inc(layouts, 1) end,
             'Next layout'),
   awful.key({ conf.modkey, "Shift" }, "space", function () awful.layout.inc(layouts, -1) end,
             'Previous layout'),

-- awful.key({ conf.modkey }, "F2", revelation.revelation)

   -- program shortcuts
   keydoc.group('Misc'),
   awful.key({ conf.modkey, }, "Return", function () awful.util.spawn(conf.apps.terminal) end,
             'Spawn a terminal'),
   awful.key({ conf.modkey, }, "c", function () awful.util.spawn(conf.apps.calendar) end,
             'Open the calendar'),
   awful.key({ conf.modkey, "Shift" }, "!", function () awful.util.spawn("xscreensaver-command --lock") end,
             'Lock the session'),

   -- facilities
   awful.key({ conf.modkey, "Shift" }, "s", function () mouse.coords(conf.param.sweep_coords) end,
             'Move the mouse out of the way'),

   -- awesome global control
   awful.key({ conf.modkey, "Shift" }, "r", awesome.restart,
             'Restart Awesome'),
   awful.key({ conf.modkey, "Shift" }, "q", awesome.quit,
             'Quit Awesome'),

   -- shifty dedicated bindings
   keydoc.group('Shifty'),
   awful.key({ conf.modkey, }, "t", function() shifty.add({ rel_index = 1 }) end, nil,
             "New tag"),
   awful.key({ conf.modkey, "Control" }, "t", function() shifty.add({ rel_index = 1, nopopup = true }) end, nil,
             "New tag in background"),
   awful.key({ conf.modkey, "Control" }, "s", tag_to_screen, nil,
             "Send tag to next screen"),
   awful.key({ conf.modkey, }, "r", shifty.rename, nil,
             "Rename tag"),
   awful.key({ conf.modkey, }, "w", shifty.del, nil,
             "Delete tag"),

   -- diagnostic
   awful.key({ conf.modkey, }, 'i', _get_tag_info, nil, "Display tag info"),

   -- Prompt
   awful.key({ conf.modkey }, "F1",
             function ()
                _prompt("Run: ", awful.util.spawn, awful.completion.bash,
                        awful.util.getdir("cache") .. "/history")
             end,
             'Prompt'),

   awful.key({ conf.modkey }, "F2",
             function () awful.util.spawn( 'dmenu_run -b -nb "' .. beautiful.bg_normal ..
                                           '" -nf "' .. beautiful.fg_normal ..
                                           '" -sb "' .. beautiful.fg_focus ..
                                           '" -sf "' .. beautiful.bg_focus .. '"') end),
   awful.key({ conf.modkey }, "F3",
             function ()
                _prompt("Web search: ",
                        function (command)
                           awful.util.spawn("uzbl 'http://yubnub.org/parser/parse?command=" .. command .. "'", false) end, nil,
                        awful.util.getdir("cache") .. "/history_web")
             end,
             'Web search'),

   awful.key({ conf.modkey }, "F4",
             -- TODO: the wibox doesn't get closed if the Lua expression has an error.
             function ()
                _prompt("Run Lua code: ",
                        awful.util.eval, nil,
                        awful.util.getdir("cache") .. "/history_eval")
             end,
             'Lua prompt'),

   -- Special keys
   awful.key({ }, "XF86AudioMute", function () awful.util.spawn('amixer -c 0 set Master toggle') end),
   awful.key({ }, "XF86AudioRaiseVolume", function () awful.util.spawn('amixer -c 0 set Master 5+db') end),
   awful.key({ }, "XF86AudioLowerVolume", function () awful.util.spawn('amixer -c 0 set Master 5-db') end),
   awful.key({ }, "XF86AudioPlay", function () awful.util.spawn('xmms2 toggleplay') end),
   awful.key({ }, "XF86AudioNext", function () awful.util.spawn('xmms2 next') end),
   awful.key({ }, "XF86AudioStop", function () awful.util.spawn('xmms2 stop ') end),
   awful.key({ }, "XF86AudioPrev", function () awful.util.spawn('xmms2 prev ') end),
   awful.key({ }, "XF86WWW", function () awful.util.spawn('iceweasel') end),
   awful.key({ }, "XF86Mail", function () awful.util.spawn('urxvt -e mutt') end),
   awful.key({ }, "XF86Messenger", function () awful.util.spawn('xchat') end),

   -- For keyboard missing so-called multimedia keys
   awful.key({ conf.modkey }, "#127", function () awful.util.spawn('xmms2 toggleplay') end),

   -- Help
   awful.key({ conf.modkey }, "*", keydoc.display)
)

-- Client bindings
conf.bindings.client = awful.util.table.join(
   keydoc.group("Window-specific bindings"),
   awful.key({ conf.modkey, "Control" }, "f", function (c) c.fullscreen = not c.fullscreen end,
             'Fullscreen'),
   awful.key({ conf.modkey, "Control" }, "c", function (c) c:kill() end,
             'Kill'),
   awful.key({ conf.modkey, "Control" }, "space", awful.client.floating.toggle,
             'Toggle floating'),
   awful.key({ conf.modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end,
             'Switch with master window'),
   awful.key({ conf.modkey, "Control" }, "o", awful.client.movetoscreen,
             'Move to next screen'),
   awful.key({ conf.modkey, "Control" }, "r", function (c) c:redraw() end,
             'Redraw'),
   awful.key({ conf.modkey, "Control" }, "*", awful.client.togglemarked,
             'Toggle mark'),
   awful.key({ conf.modkey, "Control" }, "m",
             function (c)
                c.maximized_horizontal = not c.maximized_horizontal
                c.maximized_vertical   = not c.maximized_vertical
                if c.maximized_horizontal and c.maximized_vertical then
                   c.border_color = beautiful.border_max_focus
                else
                   c.border_color = beautiful.border_focus
                end
             end,
             'Maximise'),

   -- opacity
   awful.key({ conf.modkey, }, "Prior",
             function (c)
                if c.opacity < 1.0 then
                      c.opacity = c.opacity + 0.1
                end
             end),

   awful.key({ conf.modkey, }, "Next",
             function (c)
                if c.opacity > 0.1 then
                      c.opacity = c.opacity - 0.1
                end
             end),

   -- diagnostic
   awful.key({ conf.modkey, "Control" }, 'i',
             _get_client_info, nil, "client info")
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
