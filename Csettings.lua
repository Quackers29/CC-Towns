local x,y,z = gps.locate()
local townFolder = "Town_X"..x.."Y"..y.."Z"..z
local town = "Towns\\"..townFolder.."\\"
local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".json"
shell.run("edit "..SettingsFile)