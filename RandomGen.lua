local Utility = require("Utility")
local adminFile = "AdminSettings.json"

while true do
    local Alltowns = Utility.FindAllTowns()
    if #Alltowns > 0 then
        local RandomTown = Alltowns[math.random(1, #Alltowns)]
        local Admin = Utility.readJsonFile(adminFile)
        local result, message, score = commands.scoreboard.players.get("GenState", "AllTowns")
        if Admin and score == 2 then
            local OpLocation = Utility.findNewTownLocation(Utility.FindOtherTowns(RandomTown.folderName), Admin.Generation.minDistance,Admin.Generation.maxDistance, {x = RandomTown.x, z = RandomTown.z}, Admin.Generation.spread)
            if OpLocation then
                --commands.say("New Town at x, y, z: "..OpLocation.x..", "..OpLocation.y..", "..OpLocation.z)
                --commands.clone(RandomTown.x,RandomTown.y,RandomTown.z,RandomTown.x,RandomTown.y,RandomTown.z,OpLocation.x,OpLocation.y,OpLocation.z)
                Utility.SpawnTown(OpLocation.x,OpLocation.y,OpLocation.z,Admin.ComputerId)
                os.sleep(60)
            end
        end
        if Admin and score == 3 then
            local result, message, score = commands.exec("list")
            local playerList = {}
            if result then
                -- Splitting the string at ': ' to isolate the player names
                function ExtractPlayerNames(inputstr)
                    local names = {}
                    local pattern = "online: (.+)$"
                    local players = string.match(inputstr, pattern)
                    if players then
                        for name in string.gmatch(players, "([^, ]+)") do
                            table.insert(names, name)
                        end
                    end
                    return names
                end
                playerList = ExtractPlayerNames(message[1])
            end

            if #playerList > 0 then
                for i,v in ipairs(playerList) do
                    local result, message, score = commands.scoreboard.players.get(v, "useCarrot")
                    if score > 0 then
                        local a,b,c = commands.data.get.entity(v)
                        local c= b[1]
                        local d=string.match(c, 'Pos:.-.]')
                        local x,y,z = string.match(d, "(%--%d*%.?%d+).,.(%--%d*%.?%d+).,.(%--%d*%.?%d+)")
                        local x,y,z = Utility.round(x),Utility.round(y),Utility.round(z)
                        
                        local result, message, score = commands.data.get.entity(v,"Dimension")
                        local result1, message1, score1 = commands.data.get.entity(v,"playerGameType")
                        if score1 == 1 and string.match(message[1],"minecraft:overworld") then
                            --commands.say(x,y,z)
                            Utility.SpawnTown(OpLocation.x,OpLocation.y,OpLocation.z,Admin.ComputerId)
                        end
                    end
                end
                commands.exec("scoreboard players reset * useCarrot")
            end
        end
    end
    os.sleep(10)
end