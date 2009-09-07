-- All Events management.

-- Grab environment
local awful = require('awful')
local beautiful = require('beautiful')

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end


-- Hook function to execute when focusing a client.
awful.hooks.focus.register(
   function (c)
      if not awful.client.ismarked(c) then
         c.border_color = beautiful.border_focus
      end
   end)

-- Hook function to execute when unfocusing a client.
awful.hooks.unfocus.register(
   function (c)
      if not awful.client.ismarked(c) then
         c.border_color = beautiful.border_normal
      end
   end)

-- Hook function to execute when marking a client
awful.hooks.marked.register(
   function (c)
      c.border_color = beautiful.border_marked
   end)

-- Hook function to execute when unmarking a client.
awful.hooks.unmarked.register(
   function (c)
      c.border_color = beautiful.border_focus
   end)

-- Hook function to execute when the mouse enters a client.
awful.hooks.mouse_enter.register(
   function (c)
      -- Sloppy focus, but disabled for magnifier layout
      if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
      and awful.client.focus.filter(c) then
      client.focus = c
   end
end)

-- Hook function to execute when a new client appears.
-- awful.hooks.manage.register(
--    function (c, startup)
--       -- If we are not managing this application at startup,
--       -- move it to the screen where the mouse is.
--       -- We only do it for filtered windows (i.e. no dock, etc).
--       if not startup and awful.client.focus.filter(c) then
--          c.screen = mouse.screen
--       end

--       -- Add a titlebar
--       --awful.titlebar.add(c, { modkey = conf.modkey })

--       -- Add mouse bindings
--       c:buttons(awful.util.table.join(
--                    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
--                    awful.button({ conf.modkey }, 1, awful.mouse.client.move),
--                    awful.button({ conf.modkey }, 3, awful.mouse.client.resize)
--              ))

--       -- New client may not receive focus
--       -- if they're not focusable, so set border anyway.
--       c.border_width = beautiful.border_width
--       c.border_color = beautiful.border_normal

--       -- Check if the application should be floating.
--       local cls = c.class
--       local inst = c.instance
--       if conf.apps.floats[cls] then
--          awful.client.floating.set(c, conf.apps.floats[cls])
--       elseif conf.apps.floats[inst] then
--          awful.client.floating.set(c, conf.apps.floats[inst])
--       end

--       -- Check application->screen/tag mappings.
--       local target
--       if conf.apps.tags[cls] then
--          target = conf.apps.tags[cls]
--       elseif conf.apps.tags[inst] then
--          target = conf.apps.tags[inst]
--       end
--       if target then
--          c.screen = target.screen
--          awful.client.movetotag(conf.screens[target.screen].tags[target.tag], c)
--       end

--       -- Do this after tag mapping, so you don't see it on the wrong tag for a split second.
--       client.focus = c

--       -- Set key bindings.
--       c:keys(conf.bindings.client)

--       -- Set the windows at the slave,
--       -- i.e. put it at the end of others instead of setting it master.
--       -- awful.client.setslave(c)

--       -- Honor size hints: if you want to drop the gaps between windows, set this to false.
--       -- c.size_hints_honor = false
--    end)

-- Hook function to execute when arranging the screen.
-- (tag switch, new client, etc)
awful.hooks.arrange.register(
   function (screen)
      local layout = awful.layout.getname(awful.layout.get(screen))
      if layout and beautiful["layout_" ..layout] then
         conf.screens[screen].widgets.layout.image = image(beautiful["layout_" .. layout])
      else
         conf.screens[screen].widgets.layout.image = nil
      end

      -- Give focus to the latest client in history if no window has focus
      -- or if the current window is a desktop or a dock one.
      if not client.focus then
         local c = awful.client.focus.history.get(screen, 0)
         if c then client.focus = c end
      end
   end)

-- Hook called every minute
awful.hooks.timer.register(
   60, function ()
          conf.widgets.datebox.text = os.date(" %a %b %d, %H:%M ")
       end)
