-- http://awesome.naquadah.org/wiki/index.php?title=Calendar_widget

function displayMonth(month,year,weekStart)
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

local calendar = {}
function switchNaughtyMonth(switchMonths)
   if (#calendar < 3) then return end
   local swMonths = switchMonths or 1
   calendar[1] = calendar[1] + swMonths
   calendar[3].box.widgets[2].text = displayMonth(calendar[1], calendar[2], 2)
end

mytextbox.mouse_enter = function ()
                           local month, year = os.date('%m'), os.date('%Y')
                           calendar = { month, year, 
                                        naughty.notify({
                                                          text = displayMonth(month, year, 2),
                                                          timeout = 0, hover_timeout = 0.5,
                                                          width = 200, screen = mouse.screen
                                                       })
                                     }
                        end 
mytextbox.mouse_leave = function () naughty.destroy(calendar[3]) end

mytextbox:buttons({
                     button({ }, 1, function()
                                       switchNaughtyMonth(-1)
                                    end),
                     button({ }, 3, function()
                                       switchNaughtyMonth(1)
                                    end),
                     button({ }, 4, function()
                                       switchNaughtyMonth(-1)
                                    end),
                     button({ }, 5, function()
                                       switchNaughtyMonth(1)
                                    end),
                     button({ 'Shift' }, 1, function()
                                               switchNaughtyMonth(-12)
                                            end),
                     button({ 'Shift' }, 3, function()
                                               switchNaughtyMonth(12)
                                            end),
                     button({ 'Shift' }, 4, function()
                                               switchNaughtyMonth(-12)
                                            end),
                     button({ 'Shift' }, 5, function()
                                               switchNaughtyMonth(12)
                                            end)
                  })
