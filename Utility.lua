local Utility = {}
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
    commands.scoreboard.players.set("StartUp", "AllTowns", 1)
end

function Utility.Stop()
    commands.scoreboard.players.set("StartUp", "AllTowns", 0)
    commands.scoreboard.players.set("Restart", "AllTowns", 1)
end









function Utility.calculateDistance(pos1, pos2)
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

function Utility.isChunkLoaded(x, z)
    -- Function to check if the chunk at (x, z) is loaded
    -- Return true if loaded, false otherwise
    local boolean,table,count = commands.setblock(x,-65,z,"air")
    if table[1] == "That position is not loaded" then
        return false
    else
        return true
    end
end

function Utility.findSuitableY(x, z)
    if not Utility.isChunkLoaded(x, z) then
        return nil -- Chunk is not loaded
    end

    local startY = -50
    local minY = -62
    local maxY = 100
    local groundY = nil

    -- Check upward if necessary
    if not Utility.isAirBlock(x, startY, z) then
        for y = startY, maxY do
            if Utility.isAirBlock(x, y, z) then
                groundY = Utility.findGroundLevel(x, y, z, minY)
                break
            end
        end
    else
        groundY = Utility.findGroundLevel(x, startY, z, minY)
    end

    if groundY and Utility.isSpaceAboveClear(x, groundY, z, 11) then
        return groundY + 1
    else
        return nil
    end
end

function Utility.findGroundLevel(x, startY, z, minY)
    for y = startY, minY, -1 do
        if not Utility.isAirBlock(x, y, z) then
            return y  -- Return the Y-coordinate of the ground level
        end
    end
    return nil  -- Return nil if no ground is found (e.g., over a void or an unusual world)
end


function Utility.isAirBlock(x, y, z)
    -- Check if the block at (x, y, z) is air
    local table = commands.getBlockInfo(x,y,z)
    if table.name == "minecraft:air" then
        return true
    end
    return false
end

function Utility.isSpaceAboveClear(x, groundY, z, requiredSpace)
    for y = groundY + 1, groundY + requiredSpace do
        if not Utility.isAirBlock(x, y, z) then
            return false  -- Return false if a non-air block is found
        end
    end
    return true  -- Return true if all checked blocks are air
end

-- Use findSuitableY in your town spawning logic







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
        if Utility.calculateDistance(newPos, {x = town.x, z = town.z}) < minDistance then
            return true
        end
    end
    if Utility.calculateDistance(newPos, currentPos) < minDistance then
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
    local relevantTowns = Utility.filterNearbyTowns(nearbyTowns, maxRange)
    local angleDeviationDegrees = spread or 10
    local oppositeDirectionX, oppositeDirectionZ = Utility.calculateWeightedDirection(relevantTowns, currentPos)
    local angle = math.atan2(oppositeDirectionZ, oppositeDirectionX)

    for attempt = 1, 10 do
        -- Add random deviation to the angle
        local randomizedAngle = Utility.addRandomAngleDeviation(angle, angleDeviationDegrees)

        local distance = math.random(minRange, maxRange)
        local newX = currentPos.x + distance * math.cos(randomizedAngle)
        local newZ = currentPos.z + distance * math.sin(randomizedAngle)
        local potentialNewPos = {x = Utility.round(newX), z = Utility.round(newZ)}

        if not Utility.isLocationTooClose(potentialNewPos, relevantTowns, minRange, currentPos) then
            if Utility.isChunkLoaded(potentialNewPos.x, potentialNewPos.z) then
                local OpY = Utility.findSuitableY(potentialNewPos.x, potentialNewPos.z)
                if OpY then
                    potentialNewPos.y = OpY
                    return potentialNewPos
                end
            end
        end
    end

    return nil
end


return Utility