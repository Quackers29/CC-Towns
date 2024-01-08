local Utility = {}
local McAPI   = require("McAPI")
local covertFile = "Defaults\\convert.json"
os.loadAPI("json")

function Utility.getArraySize(arr)
    local count = 0
    for _ in pairs(arr) do
        count = count + 1
    end
    return count
end

function Utility.readJsonFile(filePath)
    local file = io.open(filePath, "r+")

    if file then
        local serializedData = file:read("*a")
        file:close()

        --local luaTable = textutils.unserializeJSON(serializedData)
        local luaTable = json.decode(serializedData)

        if luaTable then
            return luaTable  -- Successfully parsed JSON
        else
            return nil  -- Failed to parse JSON
        end
    else
        return nil  -- Failed to open file
    end
end

function Utility.writeJsonFile(filePath, data)
    --local serializedData = textutils.serializeJSON(data)
    local serializedData = json.encodePretty(data)
    
    local file = io.open(filePath, "w+")

    if file then
        file:write(serializedData)
        file:close()
        return true  -- Successfully saved to file
    else
        return false  -- Failed to open file
    end
end

function Utility.copyFile(sourcePath, destinationPath)
    if fs.exists(sourcePath) and not fs.isDir(sourcePath) then
        if fs.copy(sourcePath, destinationPath) then
            return true
        else
            print("Failed to copy the file.")
            return false
        end
    else
        print("Source file does not exist or is a directory.")
        return false
    end
end

function Utility.ParseMcItemString(itemString)
    local mod, item, attributes = itemString:match("(.-):(.-),(.*)")
    if not attributes then
        mod, item = itemString:match("(.-):(.*)")
    end
    
    return {
        mod = mod,
        item = item,
        attributes = attributes or ""
    }
end

function Utility.convertItem(itemShort)
    local convertTable = Utility.readJsonFile(covertFile)
    local itemString = nil
    if convertTable then
        if convertTable[itemShort] then
            itemString = convertTable[itemShort]
        end
    end
    return itemString
end

function Utility.AddMcItemToTable(itemString, itemTable, count)
    -- Parse the item string
    local parsedData = Utility.ParseMcItemString(itemString)
    local itemTable = itemTable or {}
    -- Check if the entry exists in the table
    local exists = false
    if itemTable[itemString] ~= nil then
        exists = true
    end
    if not exists then
        -- Add to dataTable
        itemTable[itemString] = {
            attributes = parsedData.attributes,
            count = count,
            toggle = false,
            key = parsedData.item
        }
    else
        -- modify itemTable
        if count then
            itemTable[itemString].count = itemTable[itemString].count + count
            if itemTable[itemString].count < 1 then
                itemTable[itemString] = nil
            end
        end
    end

    return itemTable
end

function Utility.GetMcItemCount(itemString, itemTable)
    local itemTable = itemTable or {}
    -- Check if the entry exists in the table
    local exists = false
    if itemTable[itemString] ~= nil then
        exists = true
    end
    if not exists then
        return 0
    else
        return itemTable[itemString].count
    end
end

function Utility.ModifyMcItemInTable(itemString, itemTable, toggle)
    -- Parse the item string
    local itemTable = itemTable or {}
    -- Check if the entry exists in the table
    local exists = false
    if itemTable[itemString] ~= nil then
        exists = true
    end
    --print(itemTable[key][index].toggle)
    if not exists then
        -- Add to dataTable
        print("no item in table, itemstring: ", itemString)
    else
        -- modify itemTable
        if toggle ~= nil then
            --print(itemTable[itemString].toggle)
            itemTable[itemString].toggle = toggle
            --print(itemTable[itemString].toggle)
        end
    end

    return itemTable
end

-- This function counts the number of lines with actual data (ignoring empty or whitespace-only lines) in a text file.
function Utility.countDataLines(filePath)
    local line_count = 0
    local file = fs.open(filePath, "r") -- Open the file in read mode

    if not file then
        --print("Could not open file at " .. filePath)
        return 0 -- Return 0 if the file cannot be opened
    end

    while true do
        local line = file.readLine()
        if line == nil then break end -- End of file
        if string.match(line, "%S") then -- Check if line has non-whitespace characters
            line_count = line_count + 1
        end
    end

    file.close() -- Always close the file when done
    return line_count
end

--how many of an item is in the resource table
function Utility.ResCount(resTable, itemString)
    if resTable[itemString] then
        return resTable[itemString].count
    else
        -- if not in res table
        return 0
    end
end

-- Appends text to a file in append mode ("a").
function Utility.appendToFile(filePath, text)
    local file = io.open(filePath, "a")  -- Open the file in append mode ("a")

    if file then
        file:write(text)  -- Write the provided text to the file
        file:close()      -- Close the file
        return true       -- Return true to indicate success
    else
        return false      -- Return false to indicate failure
    end
end

-- Read a text file line by line and add non-empty lines to an array
function Utility.readTextFileToArray(filePath)
    local lines = {}  -- Initialize an empty array to store lines
    local file = io.open(filePath, "r")  -- Open the file in read mode
    if file then
        for line in file:lines() do
            if line ~= "" then
                table.insert(lines, line)  -- Add non-empty lines to the array
            end
        end
        file:close()  -- Close the file
    else
        --print("Failed to open the file")
    end
    return lines  -- Return the array of lines
end

-- Delete a file with retries
-- Parameters:
--   filePath (string): The path to the file you want to delete.
--   maxRetries (number, optional): The maximum number of deletion attempts (default is 10).
function Utility.deleteFile(filePath, maxRetries)
    maxRetries = maxRetries or 10  -- Default to 10 retries if not specified
    
    for attempt = 1, maxRetries do
        if fs.exists(filePath) then
            if fs.delete(filePath) then
                --print("File deleted successfully.")
                return true  -- Successfully deleted the file
            else
                --print("Failed to delete file on attempt " .. attempt)
            end
        else
            --print("File does not exist.")
            return false  -- File doesn't exist, no need to retry
        end
        -- Wait for 0.1 seconds before the next attempt
        os.sleep(0.1)
    end
    print(filePath.." - Failed to delete the file after all attempts")
    return false  -- Failed to delete the file after all attempts
end

-- Sorts an array based on a specified key
function Utility.sortArrayByKey(array, key)
    table.sort(array, function(a, b)
        return a[key] < b[key]
    end)
end

function Utility.Start()
    McAPI.ScoreSet("StartUp", "AllTowns", 1)
end

function Utility.Stop()
    McAPI.ScoreSet("StartUp", "AllTowns", 0)
    McAPI.ScoreSet("Restart", "AllTowns", 1)
end


function Utility.CalcDist(pos1, pos2)
    return math.sqrt((pos2.x - pos1.x)^2 + (pos2.z - pos1.z)^2)
end

function Utility.filterNearbyTowns(nearbyTowns, maxRange)
    local filteredTowns = {}
    for _, town in ipairs(nearbyTowns) do
        if town.distance <= maxRange then
            table.insert(filteredTowns, town)
        end
    end
    return filteredTowns
end

function Utility.findSuitableY(x, z)
    if not McAPI.isChunkLoaded(x, z) then
        return nil -- Chunk is not loaded
    end

    local startY = -50
    local minY = -62
    local maxY = 100
    local groundY = nil

    -- Check upward if necessary
    if not McAPI.isAirBlock(x, startY, z) then
        for y = startY, maxY do
            if McAPI.isAirBlock(x, y, z) then
                groundY = McAPI.findGroundLevel(x, y, z, minY)
                break
            end
        end
    else
        groundY = McAPI.findGroundLevel(x, startY, z, minY)
    end

    if groundY and McAPI.isSpaceAboveClear(x, groundY, z, 11) then
        return groundY + 1
    else
        return nil
    end
end

function Utility.degreesToRadians(deg)
    return deg * (math.pi / 180)
end

function Utility.radiansToDegrees(rad)
    return rad * (180 / math.pi)
end

function Utility.calculateAverageAngle(nearbyTowns)
    local sumSin, sumCos = 0, 0

    for _, town in ipairs(nearbyTowns) do
        local angle = math.atan2(town.z, town.x) -- Get angle in radians
        sumSin = sumSin + math.sin(angle)
        sumCos = sumCos + math.cos(angle)
    end

    local avgAngle = math.atan2(sumSin, sumCos)
    return avgAngle
end

function Utility.isLocationTooClose(newPos, nearbyTowns, minDistance, currentPos)
    for _, town in ipairs(nearbyTowns) do
        if Utility.CalcDist(newPos, {x = town.x, z = town.z}) < minDistance then
            return true
        end
    end
    if Utility.CalcDist(newPos, currentPos) < minDistance then
        return true
    end
    return false
end

function Utility.round(number)
    return math.floor(number + 0.5)
end

function Utility.addRandomAngleDeviation(angle, maxDeviationDegrees)
    local deviationRadians = Utility.degreesToRadians(math.random(-maxDeviationDegrees, maxDeviationDegrees))
    return angle + deviationRadians
end

function Utility.calculateWeightedDirection(nearbyTowns, currentPos)
    local sumX, sumZ = 0, 0

    for _, town in ipairs(nearbyTowns) do
        local weight = 1 / town.distance -- Inverse weight by distance
        local directionX = (town.x - currentPos.x) * weight
        local directionZ = (town.z - currentPos.z) * weight
        sumX = sumX + directionX
        sumZ = sumZ + directionZ
    end

    -- Determine the average direction (summed and normalized)
    local avgDirectionX = sumX / #nearbyTowns
    local avgDirectionZ = sumZ / #nearbyTowns

    -- Get the opposite direction
    return -avgDirectionX, -avgDirectionZ
end

function Utility.findNewTownLocation(nearbyTowns, minRange, maxRange, currentPos, spread)
    local relevantTowns = Utility.filterNearbyTowns(nearbyTowns, maxRange*2)
    local angleDeviationDegrees = spread or 10
    local safetyDist = 90 -- 2 chunks further into the void
    local oppositeDirectionX, oppositeDirectionZ = 1,1
    if #relevantTowns > 0 then
        oppositeDirectionX, oppositeDirectionZ = Utility.calculateWeightedDirection(relevantTowns, currentPos)
    end
    local angle = math.atan2(oppositeDirectionZ, oppositeDirectionX)

    for attempt = 1, 10 do
        -- Add random deviation to the angle
        local randomizedAngle = Utility.addRandomAngleDeviation(angle, angleDeviationDegrees)

        local distance = math.random(minRange, maxRange)
        local newX = Utility.round(currentPos.x + (distance * math.cos(randomizedAngle)))
        local safetyXpos = Utility.round(newX + safetyDist)
        local safetyXneg = Utility.round(newX - safetyDist)
        local newZ = Utility.round(currentPos.z + (distance * math.sin(randomizedAngle)))
        local safetyZpos = Utility.round(newZ + safetyDist)
        local safetyZneg = Utility.round(newZ - safetyDist)
        local potentialNewPos = {x = newX, z = newZ}
        --print(potentialNewPos.x,potentialNewPos.z,newX,newZ,randomizedAngle,math.cos(randomizedAngle),math.sin(randomizedAngle),angle,angleDeviationDegrees,oppositeDirectionZ, oppositeDirectionX,#relevantTowns)

        if not Utility.isLocationTooClose(potentialNewPos, relevantTowns, minRange, currentPos) then
            if McAPI.isChunkLoaded(newX, newZ) then
                if McAPI.isChunkLoaded(newX, safetyZpos) and McAPI.isChunkLoaded(newX, safetyZneg) and McAPI.isChunkLoaded(safetyXpos, newZ) and McAPI.isChunkLoaded(safetyXneg, newZ) then
                    local OpY = Utility.findSuitableY(potentialNewPos.x, potentialNewPos.z)
                    if OpY then
                        potentialNewPos.y = OpY
                        return potentialNewPos
                    end
                end
            end
        end
    end

    return nil
end

function Utility.FindAllTowns()
    local x,y,z = gps.locate()
    local AllTowns = {}
    for i,v in ipairs(fs.list("Towns")) do
        local ax, ay, az = string.match(v, "X(%-?%d+)Y(%-?%d+)Z(%-?%d+)")
        table.insert(AllTowns,{folderName = v,x = ax,y = ay,z = az, distance = Utility.CalcDist({x = x, z = z}, {x = ax,z = az})})
    end
    return AllTowns
end

function Utility.FindOtherTowns(townFolder)
    local x,y,z = gps.locate()
    local OtherTowns = {}
    for i,v in ipairs(fs.list("Towns")) do
        if v == townFolder then
        else
            local ax, ay, az = string.match(v, "X(%-?%d+)Y(%-?%d+)Z(%-?%d+)")
            table.insert(OtherTowns,{folderName = v,x = ax,y = ay,z = az, distance = Utility.CalcDist({x = x, z = z}, {x = ax,z = az})})
        end
    end
    return OtherTowns
end

function Utility.IsATown(townFolder)
    for i,v in ipairs(Utility.FindAllTowns()) do
        if v.folderName == townFolder then
            print("Town already exist")
            return true
        end
    end
    return false
end

-- Deletes the current Town and associated files
function Utility.SelfDestruct()
    local x,y,z = gps.locate()
    local townFolder = "Town_X"..x.."Y"..y.."Z"..z
    if Utility.IsATown(townFolder) then
        fs.delete("Towns\\"..townFolder.."\\")
    end
    McAPI.fillArea(x-1,y+1,z,x+1,y+3,z, "air","")
    Utility.Fireworks()
    McAPI.setBlock(x, y, z, "air")
    error("Program terminated, Computer deleted")
end

-- Summons fireworks for a Town realative to the computer
function Utility.Fireworks()
    McAPI.SummonFirework(1,7,0,1)
    McAPI.SummonFirework(0,7,0,4)
    McAPI.SummonFirework(-1,7,0,2)
    --commands.exec("summon firework_rocket ~1 ~7 ~ {LifeTime:20,FireworksItem:{id:\"minecraft:firework_rocket\",Count:1,tag:{Fireworks:{Explosions:[{Type:1,Flicker:1,Trail:1,Colors:[I;255,65280,11743532],FadeColors:[I;14602026]}]}}}}")
    --commands.exec("summon firework_rocket ~ ~7 ~ {LifeTime:20,FireworksItem:{id:\"minecraft:firework_rocket\",Count:1,tag:{Fireworks:{Explosions:[{Type:4,Flicker:1,Trail:1,Colors:[I;255,65280,11743532],FadeColors:[I;14602026]}]}}}}")
    --commands.exec("summon firework_rocket ~-1 ~7 ~ {LifeTime:20,FireworksItem:{id:\"minecraft:firework_rocket\",Count:1,tag:{Fireworks:{Explosions:[{Type:2,Flicker:1,Trail:1,Colors:[I;255,65280,11743532],FadeColors:[I;14602026]}]}}}}")
end

-- Function to split the string by a delimiter
function Utility.SplitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function Utility.SpawnTown(x,y,z,Id)
    if McAPI.ScoreGet("GenStructure", "AllTowns") == 1 then
        Utility.SpawnStructure(x,y-1,z,"structure_001")
    end
    McAPI.setBlock(x,y,z,"computercraft:computer_command{ComputerId:"..Id..",On:1}")
end

function Utility.SpawnStructure(x,y,z,name)
    McAPI.setBlock(x,y,z,"minecraft:structure_block{mode:\"LOAD\",name:\""..name.."\",posX:-10,posY:1,posZ:-8,sizeX:xSize,sizeY:ySize,sizeZ:zSize,integrity:1.0f,showboundingbox:1b} replace")
    McAPI.setBlock(x,y-1,z,"minecraft:redstone_block")
end

function Utility.GetTimestamp()
    return os.epoch("utc")
end

function Utility.PopCheck(SettingsFile,resFile)
    --Initial idea of Population, basic slow gen to Cap
    --1. Check upkeep
    --2. Tourists
    --3. POP
    local currentTimeSec = Utility.GetTimestamp()/1000
    local Settings = Utility.readJsonFile(SettingsFile)
    local resTable = Utility.readJsonFile(resFile)
    local upkeepComplete = true
    if Settings and resTable then
        
        --1. Upkeep
        if Settings.population.lastUpkeep == nil or currentTimeSec > (Settings.population.lastUpkeep + (Settings.population.upkeepTime)) then
            Settings.population.lastUpkeep = currentTimeSec
            if Settings.population.currentPop > 0  then
                for item,quantity in pairs(Settings.population.upkeepCosts) do
                    local upkeepQuantity = quantity * Settings.population.currentPop
                    local currentQuantity = Utility.GetMcItemCount(item, resTable)
                    upkeepQuantity = Utility.round(upkeepQuantity)
                    if upkeepQuantity > currentQuantity then
                        upkeepComplete = false
                    else
                        Utility.AddMcItemToTable(item, resTable, upkeepQuantity*-1)
                    end
                end
            end
        end

        --2. Tourists
        if Settings.population.lastTourist == nil or currentTimeSec > (Settings.population.lastTourist + (Settings.population.touristTime)) then
            Settings.population.lastTourist = currentTimeSec
            Settings.population.currentTourists = Utility.round(Settings.population.currentPop * Settings.population.touristRatio)
        end

        --3. PopGen
        if upkeepComplete then
            if Settings.population.lastGen == nil or currentTimeSec > (Settings.population.lastGen + (Settings.population.genTime)) then
                Settings.population.lastGen = currentTimeSec
                local continueGen = true
                for x = 1, Settings.population.gen do
                    if Settings.population.currentPop < Settings.population.cap and continueGen then

                        for item,quantity in pairs(Settings.population.genCosts) do
                            local GenQuantity = quantity
                            local currentQuantity = Utility.GetMcItemCount(item, resTable)
                            --GenQuantity = Utility.round(GenQuantity)
                            if GenQuantity > currentQuantity then
                                continueGen = false
                            else
                                Utility.AddMcItemToTable(item, resTable, GenQuantity*-1)
                            end
                        end
                        -- add gen to the pop
                        if continueGen then
                            Settings.population.currentPop = Settings.population.currentPop + 1
                            if Settings.population.popList[Settings.town.name] then
                                Settings.population.popList[Settings.town.name] = Settings.population.popList[Settings.town.name] + 1
                            else
                                Settings.population.popList[Settings.town.name] = 1
                            end
                        end
                    end
                end
            end
        end

        Utility.writeJsonFile(SettingsFile,Settings)
        Utility.writeJsonFile(resFile,resTable)
    end
end

function Utility.OutputPop(SettingsFile, count, townName, name)
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings then
        local x,y,z = Settings.population.output.x,Settings.population.output.y,Settings.population.output.z
        for i = 1,count do
            if Settings.population.currentPop > Settings.population.cap - (Settings.population.cap * Settings.population.emigrationRatio) then
                if name ~= nil then
                    if Settings.population.popList[name] then
                        if Settings.population.popList[name] > 1 then
                            Settings.population.popList[name] = Settings.population.popList[name] - 1
                            McAPI.SummonCustomVill(x,y,z,name)
                            Settings.population.currentPop = Settings.population.currentPop - 1
                        end
                    end
                else
                    local foundPop = false
                    for i,v in pairs(Settings.population.popList) do
                        if foundPop == false then
                            if v > 0 then
                                local outName = "nil"
                                if i == "Villager" then
                                    outName = townName
                                else
                                    outName = i
                                end
                                Settings.population.popList[i] = Settings.population.popList[i] - 1
                                McAPI.SummonCustomVill(x,y,z,outName)
                                Settings.population.currentPop = Settings.population.currentPop - 1
                                foundPop = true
                            end
                        end
                    end
                end
            end
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.InputPop(SettingsFile,townName,townNames,townX,townZ)
    local Settings = Utility.readJsonFile(SettingsFile)
    local hasKilled = false
    if Settings then
        local x,y,z,range = Settings.population.input.x,Settings.population.input.y,Settings.population.input.z,Settings.population.input.range
        local killed = McAPI.KillCustomVill(x,y,z,range,townName)
        if killed then
            if string.match(killed,"(T)") then
                -- Tourist handle
                local fromTown = string.match(killed,"%)(.*)")
                if fromTown == Settings.town.name then
                    --Own tourist, add
                    Settings.population.currentTourists = Settings.population.currentTourists + 1
                else
                    --from elsewhere, handle
                    local townNamesList = Utility.readJsonFile(townNames)
                    if townNamesList and townNamesList.used[fromTown] then
                        local ax,ay,az = Utility.ParseTownCords(townNamesList.used[fromTown])
                        if ax and az then
                            local distance = Utility.round(Utility.CalcDist({x = ax,z = az}, {x = townX,z = townZ}))
                            local pay = Utility.round(distance / 10)
                            McAPI.Say("Tourist travelled (m): "..distance..", for: "..pay.." emeralds")
                            McAPI.SummonItem(x,y,z, "minecraft:emerald",pay)
                            hasKilled = true
                        end
                    end
                end
            else
                -- Population
                Settings.population.currentPop = Settings.population.currentPop + 1
                if Settings.population.popList[killed] then
                    Settings.population.popList[killed] = Settings.population.popList[killed] + 1
                else
                    Settings.population.popList[killed] = 1
                end
            end

        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
    return hasKilled
end

function Utility.ParticleMarker(x,y,z)
    commands.particle("block_marker", "chest", x, y, z, 0, 0, 0, 0.5, 10, "normal")
    commands.particle("end_rod", x, y, z, 0, 0, 0, 0.03, 100, "normal")
end

function Utility.OutputTourist(SettingsFile, count, townName)
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings then
        local x,y,z,radius, max = Settings.population.output.x,Settings.population.output.y,Settings.population.output.z,Settings.population.output.radius, Settings.population.output.max
        local x2,y2,z2 = Settings.population.output.x2,Settings.population.output.y2,Settings.population.output.z2
        for i = 1,count do
            local VillagerCount = 0
            if Settings.population.output.method == "Line" then
                local dist = Utility.CalcDist({x=x,z=z},{x=x2,z=z2})
                local xh,zh = Utility.PointBetweenPoints(x,z,x2,z2, 0.5)
                VillagerCount = McAPI.GetVillagerCount(xh,y,zh, dist+Utility.round(dist*0.2)) -- add 20% check
            else
                VillagerCount = McAPI.GetVillagerCount(x,y,z, radius+Utility.round(radius*0.5)) -- add 50% check
            end
            --print(VillagerCount)
            if Settings.population.currentTourists > 0 and VillagerCount < max then
                if Settings.population.output.method == "Line" then
                    x,z = Utility.PointBetweenPoints(x,z,x2,z2, -1)
                end
                McAPI.SummonCustomVill(x,y,z,"(T)"..townName, "random")
                Settings.population.currentTourists = Settings.population.currentTourists - 1
            end
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.CheckTourist(SettingsFile, count, townName,townNames,townX,townZ)
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings and Settings.population.touristOutput == true then
        Utility.OutputTourist(SettingsFile, count, townName)
    end
    if Settings and Settings.population.autoInput == true then
        local boolean = true
        while boolean do
            boolean = Utility.InputPop(SettingsFile,"(T)"..townName,townNames,townX,townZ)
            if boolean then
                os.sleep(0.2)
            end
        end
    end
end

function Utility.ParseTownCords(name)
    local x, y, z = string.match(name, "X(%-?%d+)Y(%-?%d+)Z(%-?%d+)")
    if x and y and z then
        return x,y,z
    else
        return nil
    end
end

function Utility.PointBetweenPoints(x,z,x2,z2, factor)
    local t = factor
    if factor == -1 then
        t = math.random()  -- Random value between 0 and 1
    end
    local x = (1 - t) * x + t * x2
    local z = (1 - t) * z + t * z2
    return x,z
end


return Utility