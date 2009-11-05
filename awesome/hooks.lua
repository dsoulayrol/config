-- All Events management.

-- Grab environment
local awful = require('awful')
local beautiful = require('beautiful')
local util = require("awful.util")

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end


-- -- Hook function to execute when client properties change.
-- awful.hooks.property.register(
--    function (c)
--       if c.name and c.screen then
--          flaw.helper.debug.warn("New property: " .. util.escape(c.name))
--          conf.screens[c.screen].widgets.wtitle.text =
--             "<b><small> " .. util.escape(c.name) .. " </small></b>"
--       end
--    end)

-- Hook function to execute when focusing a client.
awful.hooks.focus.register(
   function (c)
      if not awful.client.ismarked(c) then
         c.border_color = beautiful.border_focus
      end
      if c.name and c.screen then
--         flaw.helper.debug.warn("New title: " .. util.escape(c.name))
         conf.screens[c.screen].widgets.wtitle.text =
            "<b><small> " .. util.escape(c.name) .. " </small></b>"
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
