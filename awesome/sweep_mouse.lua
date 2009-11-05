-- From: http://awesome.naquadah.org/wiki/Move_Mouse

if conf == nil then
   -- should trace something here...
   -- perhaps should bind minimal default keys (restart).
end

-- Move the mouse out of the way.
local safeCoords = { x = 1440, y = 900 }

-- Simple function to move the mouse to the coordinates set above.
local function moveMouse(x_co, y_co)
    mouse.coords({ x=x_co, y=y_co })
end

-- Bind ''Meta4+Ctrl+m'' to move the mouse to the coordinates set above.
--   this is useful if you needed the mouse for something and now want it out of the way
--keybinding({ conf.modkey, 'Control' }, 'm',
--           function() moveMouse(safeCoords.x, safeCoords.y) end):add()

-- Optionally move the mouse when rc.lua is read (startup)
if conf.param.mouse_move_aside then
   moveMouse(safeCoords.x, safeCoords.y)
end
