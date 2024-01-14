local Utility = require("Utility")
local townNames = "Defaults\\townNames.json"
local x,y,z = gps.locate()
local townFolder = "Town_X"..x.."Y"..y.."Z"..z
local town = "Towns\\"..townFolder.."\\"
local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".json"
local adminFile = "AdminSettings.json"
Utility.LoadFiles(SettingsFile,adminFile,"")


print("Computer will Self Destruct in 5 seconds")
os.sleep(5)
local townNamesList = Utility.readJsonFile(townNames)
local Settings = Utility.readJsonFile(SettingsFile)
if townNamesList and townNamesList.used and Settings and Settings.town.name ~= nil then
    townNamesList.used[Settings.town.name] = nil
    Utility.writeJsonFile(townNames,townNamesList)
end
Utility.SelfDestruct()