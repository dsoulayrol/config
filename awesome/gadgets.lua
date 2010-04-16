-- Gadgets population.

-- Grab environment
local awful = require('awful')
local flaw = require('flaw')
local beautiful = require('beautiful')
local io = require('io')

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end

-- Load local modules
conf.widgets.datebox = require('calendar')

-- Create other common widgets
conf.widgets.systray = widget{ type = "systray" }
conf.widgets.prompt = widget{ type = "textbox" }

-- GMail
conf.gadgets.gmail = flaw.gadget.GMailTextbox(
   '', { pattern = ' GMail: <span color="' .. beautiful.fg_focus .. '">$count</span> | ' })
conf.gadgets.gmail:set_tooltip('Unread messages at $timestamp:\n$mails')

-- Create CPU, CPUfreq monitor
conf.gadgets.cpu_icon = flaw.gadget.CPUIcon(
   'cpu', {}, { image = image(beautiful.icon_cpu) })

conf.gadgets.cpu_graph = flaw.gadget.CPUGraph(
   'cpu', {}, { width = 60, height = 18 })
conf.gadgets.cpu_graph.hull:set_color(beautiful.fg_normal)
conf.gadgets.cpu_graph.hull:set_border_color(beautiful.fg_normal)
conf.gadgets.cpu_graph.hull:set_background_color(beautiful.bg_normal)

-- Create network monitor
conf.gadgets.net_icon = flaw.gadget.NetIcon(
   conf.param.net_device, {}, { image = image(beautiful.icon_net) })

conf.gadgets.net_graph = flaw.gadget.NetGraph(
   conf.param.net_device, {}, { width = 60, height = 18 })
conf.gadgets.net_graph.hull:set_color(beautiful.fg_normal)
conf.gadgets.net_graph.hull:set_border_color(beautiful.fg_normal)
conf.gadgets.net_graph.hull:set_background_color(beautiful.bg_normal)

-- conf.widgets.memory_box = flaw.gadget.new('flaw.memory.textbox', '').widget

-- Create battery monitor
if flaw.battery ~= nil then
   conf.gadgets.battery_icon = flaw.gadget.BatteryIcon(
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

   conf.gadgets.battery_box = flaw.gadget.BatteryTextbox(
      conf.param.bat_device,
      { pattern = '<span color="#99aa99">$load</span>% $time' })
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


