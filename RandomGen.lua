local Utility = require("Utility")

while true do
    local Alltowns = Utility.FindAllTowns()
    if #Alltowns > 0 then
        local RandomTown = Alltowns[math.random(1, #Alltowns)]
        local Admin = Utility.readJsonFile(adminFile)
        local result, message, score = commands.scoreboard.players.get("GenState", "AllTowns")
        if score == 2 then
            local OpLocation = Utility.findNewTownLocation(Utility.FindOtherTowns(RandomTown.folderName), Admin.Generation.minDistance,Admin.Generation.maxDistance, {x = RandomTown.x, z = RandomTown.z}, Admin.Generation.spread)
            if OpLocation then
                --commands.say("New Town at x, y, z: "..OpLocation.x..", "..OpLocation.y..", "..OpLocation.z)
                commands.clone(RandomTown.x,RandomTown.y,RandomTown.z,RandomTown.x,RandomTown.y,RandomTown.z,OpLocation.x,OpLocation.y,OpLocation.z)
                os.sleep(60)
            end
        end
    end
    os.sleep(10)
end