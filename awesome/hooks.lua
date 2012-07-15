-- All Events management.

-- Grab environment
local awful = require('awful')
local beautiful = require('beautiful')
local util = require("awful.util")

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end

client.add_signal(
   'manage',
   function (c, startup)
      -- Enable sloppy focus.
      c:add_signal(
         'mouse::enter',
         function(c)
            if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
         end
      end)

      -- Center the Agenda popup.
      if c['name'] == 'agenda' then
         awful.placement.centered(c)
      else
         if not startup then
            -- Put windows in a smart way, only if they do not set an
            -- initial position.
            if not c.size_hints.user_position and not c.size_hints.program_position then
               awful.placement.no_overlap(c)
               awful.placement.no_offscreen(c)
            end
         end
      end
   end)

-- Hook function to execute when focusing a client.
client.add_signal(
   'focus',
   function(c)
      c.border_color = beautiful.border_focus
      c.opacity = 1
      if c.maximized_horizontal and c.maximized_vertical then
         c.border_color = beautiful.border_max_focus
      else
         c.border_color = beautiful.border_focus
      end
   end)

client.add_signal(
   'unfocus',
   function(c)
      c.border_color = beautiful.border_normal
      c.opacity = 0.6
   end)
