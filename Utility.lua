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


return Utility