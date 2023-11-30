local Utility = require("Utility")
--local adminFile = "AdminSettings.json"

while true do
    local Alltowns = Utility.FindAllTowns()
    commands.scoreboard.players.set("Towns", "AllTowns", #Alltowns)
    os.sleep(30)
end