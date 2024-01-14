local Utility = require("Utility")
local McAPI     = require("McAPI")
local adminFile = "AdminSettings.json"
local x,y,z = gps.locate()

while true do
    local Alltowns = Utility.FindAllTowns()
    if #Alltowns > 0 then
        local RandomTown = Alltowns[math.random(1, #Alltowns)]
        local Admin = Utility.readJsonFile(adminFile)
        local result, message, score = commands.scoreboard.players.get("GenState", "AllTowns")
        if Admin and score == 2 then
            local OpLocation = Utility.findNewTownLocation(Utility.FindOtherTowns(RandomTown.folderName), Admin.generation.minDistance,Admin.generation.maxDistance, {x = RandomTown.x, z = RandomTown.z}, Admin.generation.spread)
            if OpLocation then
                Utility.SpawnTown(OpLocation.x,OpLocation.y,OpLocation.z,McAPI.GetComputerId(x, y, z))
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
                        local xa,ya,za = string.match(d, "(%--%d*%.?%d+).,.(%--%d*%.?%d+).,.(%--%d*%.?%d+)")
                        local xa,ya,za = Utility.round(xa),Utility.round(ya),Utility.round(za)
                        
                        local result, message, score = commands.data.get.entity(v,"Dimension")
                        local result1, message1, score1 = commands.data.get.entity(v,"playerGameType")
                        if score1 == 1 and string.match(message[1],"minecraft:overworld") then
                            Utility.SpawnTown(xa,ya,za,McAPI.GetComputerId(x, y, z))
                        end
                    end
                end
                commands.exec("scoreboard players reset * useCarrot")
            end
        end
    end
    os.sleep(10)
end