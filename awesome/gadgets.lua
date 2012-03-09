-- Gadgets population.

-- Grab environment
local flaw = require('flaw')
local beautiful = require('beautiful')

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end

-- Create other common widgets
conf.widgets.systray = widget{ type = "systray" }
conf.widgets.prompt = widget{ type = "textbox" }

-- Client title
conf.gadgets.title = flaw.gadget.text.title(
   '', { pattern = ' <b><small>$title</small></b>' })

-- Calendar
conf.gadgets.calendar = flaw.gadget.text.calendar(
   '', { clock_format = ' | %a %d %B - <span color="' ..
         beautiful.fg_focus .. '">%H:%M</span>' })

-- ALSA
conf.gadgets.alsa_lbl = flaw.gadget.text.alsa(
   '0', { pattern = 'Vol.: <span color="' .. beautiful.fg_focus .. '">$volume</span>%' })

-- Create CPU, CPUfreq monitor
conf.gadgets.cpu_icon = flaw.gadget.icon.cpu(
   'cpu', {}, { image = image(beautiful.icon_cpu) })

conf.gadgets.cpu_graph = flaw.gadget.graph.cpu(
   'cpu', {}, { width = 60, height = 18 })
conf.gadgets.cpu_graph.hull:set_color(beautiful.fg_normal)
conf.gadgets.cpu_graph.hull:set_background_color(beautiful.bg_normal)

-- Create network monitor
conf.gadgets.net_icon = flaw.gadget.icon.network(
   conf.param.net_device, {}, { image = image(beautiful.icon_net) })

conf.gadgets.net_graph = flaw.gadget.graph.network(
   conf.param.net_device, {}, { width = 60, height = 18 })
conf.gadgets.net_graph.hull:set_color(beautiful.fg_normal)
conf.gadgets.net_graph.hull:set_background_color(beautiful.bg_normal)

-- Create wifi monitor
if flaw.check_module('wifi') then
   conf.gadgets.wifi_lbl = flaw.gadget.text.wifi(
      conf.param.net_device, { delay = 10, pattern = '<span color="' .. beautiful.fg_focus .. '">$essid </span>'})
   conf.gadgets.wifi_lbl:set_tooltip('<b>Access-Point:</b> $ap (<i>$mode</i>)\n<b>Link:</b> $rate Mbs ($quality)')
end

-- Create battery monitor
if flaw.check_module('battery') then
   conf.gadgets.battery_icon = flaw.gadget.icon.battery(
      conf.param.bat_device,
      {
         my_icons = {
            image(beautiful.icon_battery_low),
            image(beautiful.icon_battery_mid),
            image(beautiful.icon_battery_full)
         },
         my_load_icon = image(beautiful.icon_battery_plugged),
         my_update = function(self)
                        if self.provider.data.st_symbol == flaw.battery.STATUS_CHARGING then
                           self.widget.image = self.my_load_icon
                        else
                           self.widget.image = self.my_icons[math.floor(self.provider.data.load / 30) + 1]
                        end
                     end
      },
      {
         image = image(beautiful.icon_battery_full)
      }
   )
   conf.gadgets.battery_icon:add_event(
      flaw.event.EdgeTrigger:new{ condition = function(d) return d.load < 60 end },
      function (g) g:my_update() end
   )
   conf.gadgets.battery_icon:add_event(
      flaw.event.EdgeTrigger:new{ condition = function(d) return d.load < 30 end },
      function (g) g:my_update() end
   )
   conf.gadgets.battery_icon:add_event(
      flaw.event.EdgeTrigger:new{
         condition = function(d) return d.st_symbol == flaw.battery.STATUS_CHARGING end },
      function (g) g:my_update() end
   )
   conf.gadgets.battery_icon:add_event(
      flaw.event.LatchTrigger:new{condition = function(d) return d.load < 10 end },
      function(g) naughty.notify{
            title = "Battery Warning",
            text = "Battery low! " .. g.provider.data.load .. "% left!",
            timeout = 10,
            position = "top_right",
            fg = beautiful.fg_focus,
            bg = beautiful.bg_focus} end
   )

   conf.gadgets.battery_box = flaw.gadget.text.battery(
      conf.param.bat_device,
      { pattern = '<span color="#99aa99">$load</span>% $st_symbol' })
   conf.gadgets.battery_box:add_event(
      flaw.event.LatchTrigger:new{condition = function(d) return d.load < 60 end },
      function(g) g.pattern = '<span color="#ffffff">$load</span>%' end
   )
   conf.gadgets.battery_box:add_event(
      flaw.event.LatchTrigger:new{condition = function(d) return d.load < 30 end },
      function(g) g.pattern = '<span color="#ff6565">$load</span>%' end
   )
end

-- Create wifi monitor
-- local w_wifi_widget = wifi.widget_new('wlan0')

-- Create sound monitor
-- local w_sound_widget = sound.widget_new()


