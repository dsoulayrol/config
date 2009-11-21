-- From: http://awesome.naquadah.org/wiki/index.php?title=Calendar_widget

require('naughty')

local datebox = awful.widget.textclock({ align = "right" })
local calendar = {}

if conf == nil then
   return datebox
end


function display_month(month,year,weekStart)
   local t,wkSt=os.time{year=year, month=month+1, day=0},weekStart or 1
   local d=os.date("*t",t)
   local mthDays,stDay=d.day,(d.wday-d.day-wkSt+1)%7
   local lines = {}

   for x=0,6 do
      lines[x+1] = os.date("%a ",os.time{year=2006,month=1,day=x+wkSt})
   end
   lines[8] = "    "

   local writeLine = 1
   while writeLine < (stDay + 1) do
      lines[writeLine] = lines[writeLine] .. "   "
      writeLine = writeLine + 1
   end

   for x=1,mthDays do
      if writeLine == 8 then
         writeLine = 1
      end
      if writeLine == 1 or x == 1 then
         lines[8] = lines[8] .. os.date(" %V",os.time{year=year,month=month,day=x})
      end
      if (#(tostring(x)) == 1) then
         x = " " .. x
      end
      lines[writeLine] = lines[writeLine] .. " " .. x
      writeLine = writeLine + 1
   end
   local header = os.date("%B %Y\n",os.time{year=year,month=month,day=1})
   header = string.rep(" ", math.floor((#(lines[1]) - #header) / 2 )) .. header

   return header .. table.concat(lines, '\n')
end

function display_calendar()
   local month, year = os.date('%m'), os.date('%Y')
   calendar = { month, year,
                naughty.notify({
                                  text = string.format('<span font_desc="%s">%s</span>', 'monospace', display_month(month, year, 2)),
                                  timeout = 0, hover_timeout = 0.5,
                                  width = 200, screen = mouse.screen
                               })
             }
end

function hide_calendar()
   naughty.destroy(calendar[3])
   calendar = {}
end

function switch_display_calendar()
   if (#calendar < 3) then display_calendar() else hide_calendar() end
end

function switch_naughty_month(switchMonths)
   if (#calendar < 3) then return end
   local swMonths = switchMonths or 1
   calendar[1] = calendar[1] + swMonths
   calendar[3].box.widgets[2].text = string.format(
      '<span font_desc="%s">%s</span>', 'monospace', display_month(calendar[1], calendar[2], 2))
end

datebox:add_signal('mouse::enter', display_calendar)
datebox:add_signal('mouse::leave', hide_calendar)
datebox:buttons(
   awful.util.table.join(
      awful.button({ }, 1, function() switch_naughty_month(-1) end),
      awful.button({ }, 3, function() switch_naughty_month(1) end),
      awful.button({ }, 4, function() switch_naughty_month(-1) end),
      awful.button({ }, 5, function() switch_naughty_month(1) end),
      awful.button({ 'Shift' }, 1, function() switch_naughty_month(-12) end),
      awful.button({ 'Shift' }, 3, function() switch_naughty_month(12) end),
      awful.button({ 'Shift' }, 4, function() switch_naughty_month(-12) end),
      awful.button({ 'Shift' }, 5, function() switch_naughty_month(12) end)))

conf.bindings.global = awful.util.table.join(
   conf.bindings.global, awful.key({ conf.modkey, }, "c", switch_display_calendar))


return datebox