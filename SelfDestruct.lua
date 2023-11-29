local Utility = require("Utility")
local x,y,z = gps.locate()
local townFolder = "Town_X"..x.."Y"..y.."Z"..z
print("Computer will Self Destruct in 10 seconds")
os.sleep(10)
if Utility.IsATown(townFolder) then
    fs.delete("Towns\\"..townFolder.."\\")
end
commands.fill(x,y,z,x,y,z,"air")
