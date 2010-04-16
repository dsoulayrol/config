-- All Events management.

-- Grab environment
local awful = require('awful')
local beautiful = require('beautiful')
local util = require("awful.util")

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end

function update_title(c)
   if c and c.name and c.screen and client.focus == c then
      conf.screens[c.screen].widgets.wtitle.text =
         "<b><small> " .. util.escape(c.name) .. " </small></b>"
   end
end

function reset_title(c)
   if c and c.screen then
      conf.screens[c.screen].widgets.wtitle.text = ""
   end
end

client.add_signal(
   'manage',
   function (c, startup)
      -- Register name changes for the title widget.
      c:add_signal('property::name', update_title)

      -- Enable sloppy focus.
      c:add_signal(
         'mouse::enter',
         function(c)
            if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
         end
      end)

      if not startup then
         -- Put the window at the end of others instead of setting it
         -- master.
         -- awful.client.setslave(c)

         -- Put windows in a smart way, only if they do not set an
         -- initial position.
         if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
         end
      end
   end)

-- Hook function to execute when focusing a client.
client.add_signal(
   'focus',
   function(c)
      c.border_color = beautiful.border_focus
      update_title(c)
      c.opacity = 1
   end)

client.add_signal(
   'unfocus',
   function(c)
      c.border_color = beautiful.border_normal
      reset_title(c)
      c.opacity = 0.6
   end)
