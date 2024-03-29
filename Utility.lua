local Utility = {}
local McAPI   = require("McAPI")
local covertFile = "Defaults\\convert.json"
os.loadAPI("json")

local SettingsFile = nil
local AdminFile = nil
local ResFile = nil

-- Loads in the reused files so they do not need to be further referenced
function Utility.LoadFiles(SettingsFileIn,AdminFileIn,ResFileIn)
    SettingsFile = SettingsFileIn
    AdminFile = AdminFileIn
    ResFile = ResFileIn
end

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
    --Incase json is given an empty table, check if serialise works
    local success, errorOrMessage = pcall(function() json.encodePretty(data) end)
    if success then
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

function Utility.AddMcItemToTable(itemString, itemTable, count, damage)-- optional damage
    -- Parse the item string
    local parsedData = Utility.ParseMcItemString(itemString)
    local itemTable = itemTable or {}
    local damage = damage or 0
    -- Check if the entry exists in the table
    local exists = false
    if count ~= 0 then 
        if itemTable[itemString] ~= nil then
            --
            if itemTable[itemString].damage == damage then
                exists = true
            end
        end
        if not exists then
            -- Add to dataTable
            itemTable[itemString] = {
                attributes = parsedData.attributes,
                count = count,
                toggle = false,
                key = parsedData.item,
                damage = damage
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
    end
    return itemTable
end

function Utility.ModifyRes(itemstring,amount)
    local Resources = Utility.readJsonFile(ResFile)
    Utility.writeJsonFile(ResFile,Utility.AddMcItemToTable(itemstring,Resources,amount))
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
    Utility.removeMonitor(x,y,z)
    Utility.Fireworks()
    McAPI.setBlock(x, y, z, "air")
    error("Program terminated, Computer deleted")
end

-- Summons fireworks for a Town realative to the computer
function Utility.Fireworks()
    McAPI.SummonFirework(1,7,0,1)
    McAPI.SummonFirework(0,7,0,4)
    McAPI.SummonFirework(-1,7,0,2)
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

--UTC timestamp since epoch in milliseconds
function Utility.GetTimestamp()
    return os.epoch("utc")
end

--Time in seconds since, converted to timezone, default format "%Y-%m-%d %H:%M:%S", optional timestamp
function Utility.GetTime(format, timestamp)
    local Admin = Utility.readJsonFile(AdminFile)
    local timestamp = timestamp or Utility.GetTimestamp()
    if Admin then
        if format ~= nil and format ~= "" then
            return os.date(format, ((timestamp + Admin.main.timeZone * 3600 * 1000) / 1000))
        else
            return os.date("%Y-%m-%d %H:%M:%S", ((timestamp + Admin.main.timeZone * 3600 * 1000) / 1000))
        end
    end
end

function Utility.PopGen(upkeepBoolean,genCostBoolean)
    --Initial idea of Population, basic slow gen to Cap
    --1. Check upkeep
    --2. POP
    local currentTimeSec = Utility.GetTimestamp()/1000
    local Settings = Utility.readJsonFile(SettingsFile)
    local resTable = Utility.readJsonFile(ResFile)
    local upkeepComplete = true
    if Settings and resTable then
        local pop = Settings.population

        --1. Upkeep
        if upkeepBoolean then
            if pop.lastUpkeep == nil or currentTimeSec > (pop.lastUpkeep + (pop.upkeepTime)) then
                pop.lastUpkeep = currentTimeSec
                if pop.popCurrent > 0  then
                    for item,quantity in pairs(pop.upkeepCosts) do
                        local upkeepQuantity = quantity * pop.popCurrent
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
        end

        --2. PopGen
        if upkeepComplete then
            if pop.lastGen == nil or currentTimeSec > (pop.lastGen + (pop.genTime)) then
                pop.lastGen = currentTimeSec
                local continueGen = true
                for x = 1, pop.gen do
                    if pop.popCurrent < pop.popCap and continueGen then
                        if genCostBoolean then
                            for item,quantity in pairs(pop.genCosts) do
                                local GenQuantity = quantity
                                local currentQuantity = Utility.GetMcItemCount(item, resTable)
                                --GenQuantity = Utility.round(GenQuantity)
                                if GenQuantity > currentQuantity then
                                    continueGen = false
                                end
                            end
                        end
                        -- remove res, add gen to the pop
                        if continueGen then
                            if genCostBoolean then
                                for item,quantity in pairs(pop.genCosts) do
                                    Utility.AddMcItemToTable(item, resTable, quantity*-1)
                                end
                            end
                            pop.popCurrent = pop.popCurrent + 1
                            if pop.popList[Settings.town.name] then
                                pop.popList[Settings.town.name] = pop.popList[Settings.town.name] + 1
                            else
                                pop.popList[Settings.town.name] = 1
                            end
                        end
                    end
                end
            end
        end
        Settings.population = pop
        Utility.writeJsonFile(SettingsFile,Settings)
        Utility.writeJsonFile(ResFile,resTable)
    end
end

--Increase tourist number over time at no cost
function Utility.TouristGen()
    local currentTimeSec = Utility.GetTimestamp()/1000
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    if Settings and Admin then
        local pop = Settings.tourist
        local genTime = 60
        local touristCap = 10
        if pop.touristTime < 0 then
            genTime = Admin.tourist.genTime
        else
            genTime = pop.touristTime
        end
        if pop.touristCap < 0 then
            touristCap = Admin.tourist.genCap
        else
            touristCap = pop.touristCap
        end
        if pop.lastTourist == nil or currentTimeSec > (pop.lastTourist + genTime) then
            pop.lastTourist = currentTimeSec
            if pop.touristCurrent >= touristCap then
                pop.touristCurrent = touristCap
            else
                pop.touristCurrent = pop.touristCurrent + 1
            end
        end
        Settings.tourist = pop
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

--Increase tourist number over time at cost
function Utility.TouristGenCost()
    local currentTimeSec = Utility.GetTimestamp()/1000
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local resTable = Utility.readJsonFile(ResFile)
    if Settings and Admin and resTable then
        local pop = Settings.tourist
        local genTime = 60
        local touristCap = 10
        if pop.touristTime < 0 then
            genTime = Admin.tourist.genTime
        else
            genTime = pop.touristTime
        end
        if pop.touristCap < 0 then
            touristCap = Admin.tourist.genCap
        else
            touristCap = pop.touristCap
        end
        if pop.lastTourist == nil or currentTimeSec > (pop.lastTourist + genTime) then
            pop.lastTourist = currentTimeSec
            local continueGen = true
            local costTable = {}
            for x = 1, pop.gen do
                if pop.touristCurrent < touristCap and continueGen then

                    for item,quantity in pairs(Admin.tourist.genCosts) do
                        local GenQuantity = quantity
                        local currentQuantity = Utility.GetMcItemCount(item, resTable)
                        if GenQuantity > currentQuantity then
                            continueGen = false
                        end
                    end
                    
                    -- remove res, add gen to the pop
                    if continueGen then
                        for item,quantity in pairs(Admin.tourist.genCosts) do
                            Utility.AddMcItemToTable(item, resTable, quantity*-1)
                        end
                        pop.touristCurrent = pop.touristCurrent + 1
                    end
                end
            end
        end
        Settings.tourist = pop
        Utility.writeJsonFile(SettingsFile,Settings)
        Utility.writeJsonFile(ResFile,resTable)
    end
end

function Utility.OutputPop(count, townName, name)
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings then
        local x,y,z = Settings.population.output.x,Settings.population.output.y,Settings.population.output.z
        for i = 1,count do
            if Settings.population.popCurrent > Settings.population.popCap - (Settings.population.popCap * Settings.population.emigrationRatio) then
                if name ~= nil then
                    if Settings.population.popList[name] then
                        if Settings.population.popList[name] > 1 then
                            Settings.population.popList[name] = Settings.population.popList[name] - 1
                            McAPI.SummonCustomVill(x,y,z,name,"","green","Pop")
                            Settings.population.popCurrent = Settings.population.popCurrent - 1
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
                                McAPI.SummonCustomVill(x,y,z,outName,"","green","Pop")
                                Settings.population.popCurrent = Settings.population.popCurrent - 1
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

function Utility.InputOwnTourist()
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local hasKilled = false
    if Settings and Admin then
        local x,y,z,radius = Settings.tourist.input.x,Settings.tourist.input.y,Settings.tourist.input.z,Settings.tourist.input.radius
        local killed = McAPI.KillExactVill(x,y,z,radius,"(T)"..Settings.town.name,"Tourist")
        if killed then
            hasKilled = true
        end
    end
    return hasKilled
end

-- depreciated
function Utility.InputPop(notName,townNames,townX,townZ)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local hasKilled = false
    if Settings and Admin then
        local townString = "["..Settings.town.name.."]"
        local x,y,z,radius = Settings.tourist.input.x,Settings.tourist.input.y,Settings.tourist.input.z,Settings.tourist.input.radius
        local killed = McAPI.KillOtherVill(x,y,z,radius,notName)
        if killed then
            if string.match(killed,"(T)") then
                -- Tourist handle
                local fromTown = string.match(killed,"%)(.*)")
                if fromTown == Settings.town.name then
                    --Own tourist, add
                    Settings.tourist.touristCurrent = Settings.tourist.touristCurrent + 1
                else
                    --from elsewhere, handle
                    local townNamesList = Utility.readJsonFile(townNames)
                    if townNamesList and townNamesList.used[fromTown] then
                        local ax,ay,az = Utility.ParseTownCords(townNamesList.used[fromTown])
                        if ax and az then
                            local distance = Utility.round(Utility.CalcDist({x = ax,z = az}, {x = townX,z = townZ}))
                            
                            --distance has to be greater than minDistance
                            if distance >= Admin.tourist.payMinDist and Admin.tourist.payEnabled then
                                local pay = Utility.round(distance / Admin.tourist.payDistPerItem)
                                McAPI.SayNear(townString.." Tourist travelled: "..distance.."m, for: "..pay.."x "..Admin.tourist.payItem,x,y,z,Admin.tourist.chatDistance)
                                if Admin.tourist.dropReward then
                                    McAPI.SummonItem(x,y,z,Admin.tourist.payItem,pay)
                                else
                                    Utility.ModifyRes(Admin.tourist.payItem,pay)
                                end
                            else
                                McAPI.SayNear(townString.." Tourist travelled: "..distance.."m (Min:"..Admin.tourist.payMinDist..")",x,y,z,Admin.tourist.chatDistance)
                            end
                            local mileArray = {}
                            local mileCurrent = 0
                            if Admin.tourist.milestonesEnabled then
                                for mile,array in pairs(Admin.tourist.milestones) do
                                    local mile = tonumber(mile)
                                    if distance > mile and distance > mileCurrent then
                                        mileCurrent = mile
                                        mileArray = array
                                    end
                                end
                            end
                            if mileArray ~= {} and #mileArray > 0 then
                                --a milestone was reached
                                mileArray = mileArray[math.random(1, #mileArray)]
                                for item,quantity in pairs(mileArray) do
                                    if Admin.tourist.dropReward then
                                        McAPI.SummonItem(x,y,z,item,quantity)
                                        McAPI.SayNear(townString.." Milestone reward for "..distance.."m :"..quantity.."x "..item,x,y,z,Admin.tourist.chatDistance,"yellow")
                                    else
                                        Utility.ModifyRes(item,quantity)
                                        McAPI.SayNear(townString.." Milestone reward for "..distance.."m :"..quantity.."x "..item,x,y,z,Admin.tourist.chatDistance,"yellow")
                                    end
                                end
                            end

                            hasKilled = true
                        end
                    end
                end
            else
                -- Population
                Settings.population.popCurrent = Settings.population.popCurrent + 1
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

function Utility.InputTourists(notName,townNames,townX,townZ)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local hasKilled = false
    local distance = 0
    local fromTown = ""
    local killed = false
    local currentTimestamp = Utility.GetTimestamp()
    if Settings and Admin then
        local townString = "["..Settings.town.name.."]"
        local x,y,z,radius = Settings.tourist.input.x,Settings.tourist.input.y,Settings.tourist.input.z,Settings.tourist.input.radius
        killed = McAPI.KillOtherVill(x,y,z,radius,notName,"Tourist")
        if killed then
            if string.match(killed,"(T)") then
                -- Tourist handle
                fromTown = string.match(killed,"%)(.*)")
                if fromTown == Settings.town.name then
                    --Own tourist, add
                    Settings.tourist.touristCurrent = Settings.tourist.touristCurrent + 1
                else
                    --from elsewhere, handle
                    local townNamesList = Utility.readJsonFile(townNames)
                    if townNamesList and townNamesList.used[fromTown] then
                        local ax,ay,az = Utility.ParseTownCords(townNamesList.used[fromTown])
                        if ax and az then
                            distance = Utility.round(Utility.CalcDist({x = ax,z = az}, {x = townX,z = townZ}))
                        end
                    end
                end
            end
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
    return killed, distance, fromTown
end

function Utility.ParticleMarker(x,y,z)
    if McAPI.Init() ~= 12 then
        McAPI.Particle("block_marker", x, y, z, 0.5, 10, "target") -- or chest
        McAPI.Particle("end_rod", x, y, z, 0.03, 100)
        McAPI.Particle("sonic_boom", x, y, z, 0.01, 1)
    else
        --McAPI.Particle("block_marker", x, y, z, 0.5, 10, "target") -- or chest
        McAPI.Particle("end_rod", x, y, z, 0.03, 100)
        McAPI.Particle("spell", x, y, z, 0.01, 1)
    end
end

function Utility.OutputTourist(count, townName)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    if Settings and Admin then
        local x,y,z,radius, max = Settings.tourist.output.x,Settings.tourist.output.y,Settings.tourist.output.z,Settings.tourist.output.radius, Settings.tourist.output.max
        if max < 0 then
            --Use Admin max out
            max = Admin.tourist.maxOut
        end
        local x2,y2,z2 = Settings.tourist.output.x2,Settings.tourist.output.y2,Settings.tourist.output.z2
        for i = 1,count do
            local VillagerCount = 0
            if Settings.tourist.output.method == "Line" then
                local dist = Utility.CalcDist({x=x,z=z},{x=x2,z=z2})
                local xh,zh = Utility.PointBetweenPoints(x,z,x2,z2, 0.5)
                VillagerCount = McAPI.GetVillagerCount(xh,y,zh, dist+Utility.round(dist*0.2)) -- add 20% check
            else
                VillagerCount = McAPI.GetVillagerCount(x,y,z, radius+Utility.round(radius*0.5)) -- add 50% check
            end
            --print(Settings.tourist.touristCurrent,VillagerCount,max)
            if Settings.tourist.touristCurrent > 0 and VillagerCount < max then
                local spawned = false
                local xo,zo = x,z
                --3 attempts at finding a free spot
                for i=1, 3 do
                    if Settings.tourist.output.method == "Line" then
                        local mid = McAPI.Init() ~= 12
                        if Admin.town.gridSpacing then
                            xo,zo = Utility.RoundHPointBetweenPoints(x,z,x2,z2, -1, mid)
                        else
                            xo,zo = Utility.PointBetweenPoints(x,z,x2,z2, -1)
                        end
                    end
                    local spacing = Admin.town.villagerSpacing or 1
                    if McAPI.Init() == 12 then
                        spacing = 0
                    end
                    if McAPI.GetVillagerCount(xo,y,zo,spacing) == 0 then-- spacing, min 0.7, safeish 0.8, 1 = 1 block
                        McAPI.SummonCustomVill(xo,y,zo,"(T)"..townName, "random",Admin.tourist.textColor,"Tourist")
                        Settings.tourist.touristCurrent = Settings.tourist.touristCurrent - 1
                        spawned = true
                        break
                    end
                end
            end
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

-- Input/Output of tourist check
function Utility.TouristTransfer(count, townName,townNames,townX,townZ)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    if Settings and Settings.tourist.touristOutput == true then
        Utility.OutputTourist(count, townName)
    end
    if Settings and Admin and Settings.tourist.autoInput == true then
        Utility.MultiTouristInput(townName,townNames,townX,townZ)
    end
    if Settings and Admin and Admin.tourist.autoRideCreate == true then
        Utility.CreatePass("(T)"..townName)
    end
end

-- Input/Output of tourist check
function Utility.InputAllOwnTourists()
    local boolean = true
    local i = 0
    while boolean do
        boolean = Utility.InputOwnTourist()
        os.sleep(0.1)
        if boolean then
            i = i + 1
        end
    end
    if i > 0 then
        local Settings = Utility.readJsonFile(SettingsFile)
        Settings.tourist.touristCurrent = Settings.tourist.touristCurrent + i
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

-- Input/Output of tourist check
function Utility.MultiTouristInput(townName,townNames,townX,townZ)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local boolean, distance, fromTown = true,0,""
    local killed = {}
    local function SelectRandomReward(milestone)
        local totalWeight = 0
    
        -- Calculate total weight
        for _, reward in ipairs(milestone) do
            totalWeight = totalWeight + (reward.weight or 1)
        end
    
        -- Randomly select a reward based on weights
        local randomValue = math.random() * totalWeight
        local currentWeight = 0
    
        for _, reward in ipairs(milestone) do
            currentWeight = currentWeight + (reward.weight or 1)
    
            if randomValue <= currentWeight then
                return reward
            end
        end
    end

    if Admin and Settings then
        while boolean do
            boolean, distance, fromTown = Utility.InputTourists("(T)"..townName,townNames,townX,townZ)
            if boolean then
                --distance has to be greater than minDistance
                local pay = 0
                if distance >= Admin.tourist.payMinDist and Admin.tourist.payEnabled then
                    pay = Utility.round(distance / Admin.tourist.payDistPerItem)
                end

                local mileArray = {}
                local mileCurrent = 0
                local milestones = {}
                local mile = 0
                if Admin.tourist.milestonesEnabled then
                    for mile,array in pairs(Admin.tourist.milestones) do
                        local mile = tonumber(mile)
                        if distance > mile and distance > mileCurrent and mile >= mileCurrent then
                            mileCurrent = mile
                            mileArray = array
                        end
                    end
                end

                if mileArray ~= {} and #mileArray > 0 then
                    --a milestone was reached
                    --mileArray = mileArray[math.random(1, #mileArray)]-- weighted
                    mileArray = SelectRandomReward(mileArray)
                    table.insert(milestones, {mile = mileCurrent, item = mileArray.item, quantity = mileArray.quantity})
                end

                table.insert(killed,{dist = distance, from = fromTown, pay = pay, milestones = milestones})
                os.sleep(0.2)
            end
        end

        if #killed > 0 then
            local townString = "["..Settings.town.name.."]"
            local x,y,z = Settings.tourist.input.x,Settings.tourist.input.y,Settings.tourist.input.z
            local tourists = #killed
            local pay = 0
            local totalDistance = 0
            local maxDistance = -math.huge
            local minDistance = math.huge
            for _, data in ipairs(killed) do
                pay = pay + data.pay
                totalDistance = totalDistance + data.dist
                if data.dist > maxDistance then
                    maxDistance = data.dist
                end
                if data.dist < minDistance then
                    minDistance = data.dist
                end
            end
            local avgDist = Utility.round(totalDistance / tourists)

            McAPI.SayNear(townString.." "..tourists.." Tourist(s) travelled (Min/Avg/Max): "..minDistance.."/"..avgDist.."/"..maxDistance.." m, for a total of: "..pay.."x "..Admin.tourist.payItem,x,y,z,Admin.tourist.chatDistance)
            if Admin.tourist.dropReward then
                McAPI.SummonItem(x,y,z,Admin.tourist.payItem,pay)
            else
                Utility.ModifyRes(Admin.tourist.payItem,pay)
            end
            -- Function to aggregate milestones
            local function aggregateMilestones(data)
                local aggregatedMilestones = {}

                for _, entry in ipairs(data) do
                    local milestones = entry.milestones
                    local currentMile = ""
                    if milestones ~= {} then
                        for _, milestone in ipairs(milestones) do
                            local mile = milestone.mile
                            currentMile = mile
                            local item = milestone.item
                            local quantity = milestone.quantity

                            if not aggregatedMilestones[mile] then
                                aggregatedMilestones[mile] = {}
                            end

                            if not aggregatedMilestones[mile][item] then
                                aggregatedMilestones[mile][item] = quantity
                            else
                                aggregatedMilestones[mile][item] = aggregatedMilestones[mile][item] + quantity
                            end
                        end
                        --Add the counter per mile (Tourists achieved per milestone)
                        if currentMile ~= "" then
                            if not aggregatedMilestones[currentMile] then
                                aggregatedMilestones[currentMile] = {}
                            end
                            if not aggregatedMilestones[currentMile]["-1"] then
                                aggregatedMilestones[currentMile]["-1"] = 1
                            else
                                aggregatedMilestones[currentMile]["-1"] = aggregatedMilestones[currentMile]["-1"] + 1
                            end
                        end
                    end
                end

                return aggregatedMilestones
            end
            --
            -- Call the function with your perVillager table
            local result = aggregateMilestones(killed)

            if result and result ~= {} then
                for mile,data in pairs(result) do
                    local tCount = data["-1"]
                    if tCount > 0 then
                        McAPI.SayNear(townString.." Milestone reward for getting "..tCount.." Tourists >"..mile.."m :",x,y,z,Admin.tourist.chatDistance,"yellow")
                        for item, quantity in pairs(data) do
                            if item ~= "-1" then
                                local parsed = Utility.ParseMcItemString(item)
                                McAPI.SayNear(" - "..quantity.."x "..parsed.item or item,x,y,z,Admin.tourist.chatDistance,"yellow")
                                if Admin.tourist.dropReward then
                                    McAPI.SummonItem(x,y,z,item,quantity)
                                else
                                    Utility.ModifyRes(item,quantity)
                                end
                            end
                        end
                        
                    end
                end
                McAPI.SayNear(" ---------- ",x,y,z,Admin.tourist.chatDistance,"yellow")
            end

            local Settings = Utility.readJsonFile(SettingsFile)
            local currentTimestamp = Utility.GetTimestamp()
            if Settings then
                local killTable = {}
                for i,v in ipairs(killed) do
                    if killTable[v.from] == nil then
                        killTable[v.from] = 1
                    else
                        killTable[v.from] = killTable[v.from] + 1
                    end
                end
                local killString = ""
                for i,v in pairs(killTable) do
                    killString = killString..v.."x "..i.." "
                    --print(killString)
                end
                Settings.tourist.History[tostring(currentTimestamp)] = killString
                --Delete any history items over the max items
                local keys = {}
                for key in pairs(Settings.tourist.History) do
                    table.insert(keys, tonumber(key))
                end
    
                table.sort(keys, function(a, b)
                    return a > b
                end)

                if #keys > Admin.tourist.historyMax then
                    for i = (Admin.tourist.historyMax + 1), #keys do
                        Settings.tourist.History[tostring(keys[i])] = nil
                    end
                end   
            end
            Utility.writeJsonFile(SettingsFile,Settings)
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

-- Function to round to the nearest 0.5
function Utility.RoundHalf(value)
    return math.floor(value * 2 + 0.5) / 2
end

-- Function to find a point between two points
function Utility.RoundHPointBetweenPoints(x, z, x2, z2, factor, midpoint)
    local t = factor
    if factor == -1 then
        t = math.random()  -- Random value between 0 and 1
    end
    if midpoint then
        x = Utility.RoundHalf((1 - t) * x + t * x2)  -- Round to the nearest 0.5
        z = Utility.RoundHalf((1 - t) * z + t * z2)  -- Round to the nearest 0.5
    else
        x = Utility.round((1 - t) * x + t * x2)  -- Round to the nearest 0.5
        z = Utility.round((1 - t) * z + t * z2)  -- Round to the nearest 0.5
    end
    return x, z
end

-- Function to read data from a CSV file into a 2D array with a tab delimiter and handle Excel's escaped double quotes
function Utility.readCSV(filename)
    local headers = {"id", "count", "toggle"}
    local data = {} -- Initialize the 2D array
    local file = io.open(filename, "r+") -- Open the file in read mode
    if file then
        local headerRow = file:read("*line")
        if headerRow ~= nil then

            -- Read header row
            local headerValues = {}
            for value in headerRow:gmatch("[^,]+") do
                table.insert(headerValues, value)
            end

            -- Read data rows
            for line in file:lines() do
                local row = {} -- Initialize a new row
                local count = 1
                -- Split the line into values using tab as the delimiter
                for value in line:gmatch("([^\t]+)") do
                    -- Convert the value to number if it's a number, otherwise keep it as a string
                    local escapedValue = tostring(value):gsub('""', '\\"') -- Escape tab characters if found
                    -- Check if the input string has encapsulated quotes and remove them
                    local outputString = escapedValue:match('^"(.*)"$') or escapedValue
                    local numValue = tonumber(value)
                    local boolValue = value:lower()
                    if boolValue == "true" then
                        row[headers[count]] = true
                    elseif boolValue == "false" then
                        row[headers[count]] = false
                    elseif numValue then
                        row[headers[count]] = numValue
                    else
                        row[headers[count]] = outputString
                    end
                    count = count + 1
                end
                table.insert(data, row) -- Add the row to the 2D array
            end
            file:close() -- Close the file when done
        else
            print("Error: Unable to read file")
        end
    else
    print("Error: Unableto open the file. ")
    end
    return data
end

function Utility.outputItems(itemString,EXPx,EXPy,EXPz)
	local r1,r3 = McAPI.GetBlockItems(EXPx,EXPy,EXPz)
    local save = false
	if r1 == true then
		if r3 == "" then -- no items in chest
			local resTable = Utility.readJsonFile(ResFile)
			if resTable ~= {} then
				local flag = true
				local outputID = ""
				local outputTag = ""
				local count = 0
                local damage = 0
				if resTable[itemString] then
                    local item = resTable[itemString]
                    damage = item.damage
                    --while flag do
                        local flagTag = string.match(itemString,"(.-.),")
                        if flagTag ~= nil then
                            outputTag = string.match(itemString,',(.*)')
                            outputID = flagTag
                        else
                            outputID = itemString
                            outputTag = ""
                        end
                        if item.count > 64 then
                            item.count = item.count-64
                            count = 64
                            flag = false
                        else
                            if item.count > 0 then
                                count = item.count
                                item.count = 0
                                flag = false                            
                            end
                            local Settings = Utility.readJsonFile(SettingsFile)
                            if Settings and Settings.resources.continuousOutput then
                                if item.toggle == false or item.toggle == "false" then
                                    resTable[itemString] = nil
                                end
                            else
                                resTable[itemString] = nil  -- removes infinite toggle on for now
                            end
                        end
                    --end
                end
                if flag == false then
                    McAPI.SetBlockItems(EXPx,EXPy,EXPz,outputID,count,outputTag,damage)
                end
                Utility.writeJsonFile(ResFile, resTable)
			end
		end
	end
end

function Utility.removeFirstLevelBrackets(input)
	local result = {}
	local level = 0
	local current = ""

	for char in input:gmatch(".") do
		if char == "{" then
			level = level + 1
			if level > 1 then
				current = current .. char
			end
		elseif char == "}" then
			level = level - 1
			if level == 0 then
				table.insert(result, current)
				current = ""
			else
				current = current .. char
			end
		else
			if level ~= 0 then
				current = current .. char
			end
		end
	end
	return result
end

function Utility.inputItems(INx,INy,INz)
	local itemTable = Utility.readJsonFile(ResFile)
	local INq,INw = McAPI.GetBlockItems(INx,INy,INz)
    local cloneHeight = McAPI.GetWorldFloor()

    if INq and McAPI.Init() == 12 then
        --check for damaged items -- do not add chest
        for match in INw:gmatch('Damage:(%d+)') do
            local damage = tonumber(match)
            if damage > 0 then
                INq = false
            end
        end
    end

	if INq and INw ~= "" then
		-- Move chest using clone to preserve contents when reading it. 
        commands.clone(INx,INy,INz,INx,INy,INz,INx,cloneHeight,INz, "replace", "move")
        local INa,INb = McAPI.GetBlockItems(INx,cloneHeight,INz)

		McAPI.SetBlockItemsEmpty(INx,cloneHeight,INz)

        commands.clone(INx,cloneHeight,INz,INx,cloneHeight,INz,INx,INy,INz, "replace", "move")

		local output = Utility.removeFirstLevelBrackets(INb)
        --print("Output: "..output)
        local space = " "
        if McAPI.Init() == 12 then
            space = ""
        end
		for _, k in ipairs(output) do
			local slot = string.match(k,"Slot:"..space.."(%d+)")
			local id = string.sub(string.match(k,"id:"..space.."(.-.),"),2,-2)
			local count = tonumber(string.match(k,"Count:"..space.."(%d+)"))
            --local tag = string.match(k,"tag:"..space.."{(.*).")
			local tag = string.match(k,"tag:"..space.."(%b{})")
            local damage = tonumber(string.match(k,"Damage:"..space.."(%d+)")) or 0

			if tag ~= nil then
                tag = string.sub(tag,2,-2)
				id = id..","..tag
			end
            --print(id.." : "..count)
            --start new parse here
            itemTable = Utility.AddMcItemToTable(id,itemTable,count, damage)
		end
		Utility.writeJsonFile(ResFile, itemTable)
	end
end

function Utility.checkItems(OUTx,OUTy,OUTz)
    local resTable = Utility.readJsonFile(ResFile)
    if resTable then
        for key,item in pairs(resTable) do
            if (item.toggle == true and item.count > 0) or (item.toggle == false and item.count == 0)  then
                Utility.outputItems(key,OUTx,OUTy,OUTz)
            end
        end
    end
end

-- Currently unused
function Utility.InRange(value, origin, range)
    return math.max(origin - range, math.min(value, origin + range))
end

-- Currently unused
function Utility.IsInRange(value, origin, range)
    return value >= (origin - range) and value <= (origin + range)
end

-- Currently unused
function Utility.IsInRange2DAngular(X, Z, originX, originZ, range)
    local distance = math.sqrt((X - originX)^2 + (Z - originZ)^2)
    return distance <= range
end

function Utility.CoerceInRange2DAngular(X, Z, originX, originZ, range)
    local dx = X - originX
    local dz = Z - originZ
    local distance = math.sqrt(dx^2 + dz^2)
    
    if distance <= range then
        return X, Z  -- Point is within range, return it as is
    end

    -- Calculate scaling factor
    local scale = range / distance

    -- Coerce point to be on the border of the circle with radius `range`
    local coercedX = originX + dx * scale
    local coercedZ = originZ + dz * scale
    
    return coercedX, coercedZ, distance
end

function Utility.CopyIfMissing(defaultFile,File)
    if not fs.exists(File) then
        Utility.copyFile(defaultFile,File)
    end
end

function Utility.buildMonitor(x,y,z)
    local Admin = Utility.readJsonFile(AdminFile)
    if McAPI.isAirBlock(x, y+1, z) and Admin then
        local facing = McAPI.GetFacing(x,y,z)
        local out = Admin.generation.monitorOut -- blocks out from the centre of monitor
        local high = Admin.generation.monitorHigh --  block high of monitor
        if facing then
            local x1,x2,z1,z2 = x,x,z-out,z+out
            if facing == "north" or facing == "south" then
                x1,x2,z1,z2 = x-out,x+out,z,z
            end
            McAPI.fillArea(x1,y+1,z1,x2,y+high,z2, "computercraft:monitor_advanced[facing="..facing.."]{width:1}")
        end
    end
end

function Utility.removeMonitor(x,y,z)
    local Admin = Utility.readJsonFile(AdminFile)
    if Admin and Admin.generation.monitorBuild then
        local facing = McAPI.GetFacing(x,y,z)
        local out = Admin.generation.monitorOut -- blocks out from the centre of monitor
        local high = Admin.generation.monitorHigh --  block high of monitor
        if facing then
            local x1,x2,z1,z2 = x,x,z-out,z+out
            if facing == "north" or facing == "south" then
                x1,x2,z1,z2 = x-out,x+out,z,z
            end
            McAPI.fillArea(x1,y+1,z1,x2,y+high,z2, "minecraft:air")
        end
    end
end

function Utility.BuildInOut(facing)
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings then
        McAPI.SetBlockSafe(Settings.resources.input.x,Settings.resources.input.y,Settings.resources.input.z, "minecraft:chest", facing)
        McAPI.SetBlockSafe(Settings.resources.output.x,Settings.resources.output.y,Settings.resources.output.z, "minecraft:chest", facing)
        McAPI.SetBlockSafe(Settings.tourist.output.x,Settings.tourist.output.y,Settings.tourist.output.z, "minecraft:torch",nil)
        McAPI.SetBlockSafe(Settings.tourist.output.x2,Settings.tourist.output.y2,Settings.tourist.output.z2, "minecraft:torch",nil)
    end
end

function Utility.InitInOut(x,y,z)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    if Settings and Admin then
        local facing = McAPI.GetFacing(x,y,z)
        local ChestRange = Admin.town.maxChestRange

        local inChest,outChest,inPop,outPop,outPop2 = {0,0,0},{0,0,0},{0,0,0},{0,0,0},{0,0,0}
        if facing == "north" then
            inChest,outChest,inPop,outPop,outPop2 = {1,1,-3},{-1,1,-3},{3,1,-4},{3,1,-2},{3,1,-6}
        elseif facing == "east" then
            inChest,outChest,inPop,outPop,outPop2 = {3,1,1},{3,1,-1},{4,1,3},{2,1,3},{6,1,3}
        elseif facing == "south" then
            inChest,outChest,inPop,outPop,outPop2 = {-1,1,3},{1,1,3},{-3,1,4},{-3,1,2},{-3,1,6}
        elseif facing == "west" then
            inChest,outChest,inPop,outPop,outPop2 = {-3,1,-1},{-3,1,1},{-4,1,-3},{-2,1,-3},{-6,1,-3}
        end

        if Settings.resources.input.x == nil then
            Settings.resources.input.x, Settings.resources.input.y, Settings.resources.input.z = x+inChest[1],y+inChest[2],z+inChest[3]
        end

        if Settings.resources.output.x == nil then
            Settings.resources.output.x, Settings.resources.output.y, Settings.resources.output.z = x+outChest[1],y+outChest[2],z+outChest[3]
        end

        if Settings.tourist.input.x == nil then
            Settings.tourist.input.x, Settings.tourist.input.y, Settings.tourist.input.z, Settings.tourist.input.range = x+inPop[1],y+inPop[2],z+inPop[3],10
        end

        if Settings.tourist.output.x == nil then
            Settings.tourist.output.x, Settings.tourist.output.y, Settings.tourist.output.z = x+outPop[1],y+outPop[2],z+outPop[3]
            Settings.tourist.output.x2, Settings.tourist.output.y2, Settings.tourist.output.z2 = x+outPop2[1],y+outPop2[2],z+outPop2[3]
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.ChangeInputChest(ax,ay,az)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local x,y,z = gps.locate()
    if Settings and Admin then
        local ChestRange = Admin.town.maxChestRange
        local INx,INy,INz = Settings.resources.input.x,Settings.resources.input.y,Settings.resources.input.z
        INx = math.max(x - ChestRange, math.min(INx + ax, x + ChestRange))
        INy = math.max(y - ChestRange, math.min(INy + ay, y + ChestRange))
        INz = math.max(z - ChestRange, math.min(INz + az, z + ChestRange))
        Settings.resources.input.x,Settings.resources.input.y,Settings.resources.input.z = INx,INy,INz
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.ChangeOutputChest(ax,ay,az)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local x,y,z = gps.locate()
    if Settings and Admin then
        local ChestRange = Admin.town.maxChestRange
        local OUTx,OUTy,OUTz = Settings.resources.output.x,Settings.resources.output.y,Settings.resources.output.z
        OUTx = math.max(x - ChestRange, math.min(OUTx + ax, x + ChestRange))
        OUTy = math.max(y - ChestRange, math.min(OUTy + ay, y + ChestRange))
        OUTz = math.max(z - ChestRange, math.min(OUTz + az, z + ChestRange))
        Settings.resources.output.x,Settings.resources.output.y,Settings.resources.output.z = OUTx,OUTy,OUTz
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.ChangeInputPop(ax,ay,az)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local x,y,z = gps.locate()
    if Settings and Admin then
        local PopRange = Admin.town.maxSpawnRange
        local PINx,PINy,PINz = Settings.tourist.input.x,Settings.tourist.input.y,Settings.tourist.input.z
        PINx = math.max(x - PopRange, math.min(PINx + ax, x + PopRange))
        PINy = math.max(y - PopRange, math.min(PINy + ay, y + PopRange))
        PINz = math.max(z - PopRange, math.min(PINz + az, z + PopRange))
        Settings.tourist.input.x,Settings.tourist.input.y,Settings.tourist.input.z = PINx,PINy,PINz
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.ChangeInputPopR(a)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    if Settings and Admin then
        local radius = Settings.tourist.input.radius
        local tempa = math.max(1, math.min(radius + a, Admin.town.maxSpawnRange))
        Settings.tourist.input.radius = tempa
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.ChangeOutputPop(ax,ay,az,select)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local x,y,z = gps.locate()
    if Settings and Admin then
        local POUTx,POUTy,POUTz = Settings.tourist.output.x,Settings.tourist.output.y,Settings.tourist.output.z
        local POUTx2,POUTy2,POUTz2 = Settings.tourist.output.x2,Settings.tourist.output.y2,Settings.tourist.output.z2
        local PopRange = Admin.town.maxSpawnRange
        local maxLineLength = Admin.town.maxLineLength
        if select == 1 then
            local tempx = math.max(x - PopRange, math.min(POUTx + ax, x + PopRange))
            POUTy = math.max(y - PopRange, math.min(POUTy + ay, y + PopRange))
            local tempz = math.max(z - PopRange, math.min(POUTz + az, z + PopRange))
            if Utility.IsInRange2DAngular(tempx,tempz,POUTx2,POUTz2,maxLineLength) then
                POUTx = tempx
                POUTz = tempz
                Settings.tourist.output.x,Settings.tourist.output.y,Settings.tourist.output.z = POUTx,POUTy,POUTz
            end
        else
            local tempx = math.max(x - PopRange, math.min(POUTx2 + ax, x + PopRange))
            POUTy2 = math.max(y - PopRange, math.min(POUTy2 + ay, y + PopRange))
            local tempz = math.max(z - PopRange, math.min(POUTz2 + az, z + PopRange))
            if Utility.IsInRange2DAngular(tempx,tempz,POUTx,POUTz,maxLineLength) then
                POUTx2 = tempx
                POUTz2 = tempz
                Settings.tourist.output.x2,Settings.tourist.output.y2,Settings.tourist.output.z2 = POUTx2,POUTy2,POUTz2
            end
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
end

function Utility.ChangeName(newName)
    local Settings = Utility.readJsonFile(SettingsFile)
    local Admin = Utility.readJsonFile(AdminFile)
    local townNames = "Defaults\\townNames.json"
    local townNamesList = Utility.readJsonFile(townNames)
    if Settings and Admin and townNamesList then
        local oldName = Settings.town.name
        Settings.town.name = newName
        Utility.writeJsonFile(SettingsFile,Settings)
        for i,v in pairs(townNamesList.used) do
            if i == oldName then
                local oldLocation = townNamesList.used[i]
                townNamesList.used[i] = nil
                townNamesList.used[newName] = oldLocation
            end
        end
        Utility.writeJsonFile(townNames,townNamesList)
    else
        print("Could not open files...")
    end
end

--if there is a create train stopped in range, finds empty seats and mounts any villagers of the passenger name onto the seats
function Utility.CreatePass(Passenger)
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings then
        local x,y,z,range, max = Settings.tourist.output.x,Settings.tourist.output.y,Settings.tourist.output.z,Settings.tourist.output.radius, Settings.tourist.output.max
        local Passenger = "@e[type=minecraft:villager,name=\""..Passenger.."\",limit=1,distance=.."..range..",nbt={OnGround:1b},x="..x..",y="..y..",z="..z.."]"
        local boolean, table, count = commands.exec("data get entity @e[type=create:carriage_contraption,limit=1,nbt={Motion:[0.0d,0.0d,0.0d]},distance=.."..range..",x="..x..",y="..y..",z="..z.."] Contraption.Seats")
        if boolean then
            local FreeSeatsTable = {}
            for i=1,count do
                FreeSeatsTable[i-1] = i-1
            end
            local boolean, table, PassCount = commands.exec("data get entity @e[type=create:carriage_contraption,limit=1,nbt={Motion:[0.0d,0.0d,0.0d]},distance=.."..range..",x="..x..",y="..y..",z="..z.."] Contraption.Passengers")
            local pboolean, result = pcall((function() textutils.unserialiseJSON(string.match(table[1],"(%b[])"),{nbt_style=true}) end))
            if pboolean and PassCount < count then
                result = textutils.unserialiseJSON(string.match(table[1],"(%b[])"),{nbt_style=true})
                for i,v in ipairs(result) do
                    FreeSeatsTable[v.Seat] = nil
                end
                local flag = true
                for i,v in pairs(FreeSeatsTable) do
                    if flag then
                        local boolean, table, count = commands.exec("/create passenger "..Passenger.." @e[type=create:carriage_contraption,limit=1,nbt={Motion:[0.0d,0.0d,0.0d]},distance=.."..range..",x="..x..",y="..y..",z="..z.."] "..v)
                        if not boolean then
                            flag = false
                        end
                    end
                end
            end
        end
    end
end

return Utility