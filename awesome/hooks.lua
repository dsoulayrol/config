-- All Events management.

-- Grab environment
local awful = require('awful')
local beautiful = require('beautiful')
local util = require("awful.util")

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end


-- Hook function to execute when client properties change.
client.add_signal(
   'property::name',
   function (c)
      flaw.helper.debug.warn("* DEBUG* Signal name raised!")
   end)

-- Hook function to execute when focusing a client.
client.add_signal(
   'focus',
   function(c)
      -- flaw.helper.debug.warn("* DEBUG* Signal focus raised!")
      c.border_color = beautiful.border_focus
      if c.name and c.screen then
         conf.screens[c.screen].widgets.wtitle.text =
            "<b><small> " .. util.escape(c.name) .. " </small></b>"
      end
   end)

client.add_signal(
   'unfocus',
   function(c)
      c.border_color = beautiful.border_normal
      conf.screens[c.screen].widgets.wtitle.text = ""
   end)

-- Hook function to execute when the mouse enters a client.
client.add_signal(
   'mouse::enter',
   function (c)
      -- Sloppy focus, but disabled for magnifier layout
      if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
         and awful.client.focus.filter(c) then
         client.focus = c
      end
   end)
