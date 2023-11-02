local Utility = {}
local covertFile = "Defaults\\convert.json"

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

        local luaTable = textutils.unserializeJSON(serializedData)

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
    local serializedData = textutils.serializeJSON(data)
    
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
    local key, index = nil, nil
    for k, items in pairs(itemTable) do
        if k == parsedData.item then
            for i, item in pairs(items) do
                if item.string == itemString then
                    exists = true
                    key, index = k,i
                    break
                end
            end
            if exists then break end
        end
    end
    if not exists then
        -- Add to dataTable
        if not itemTable[parsedData.item] then
            itemTable[parsedData.item] = {}
        end
        table.insert(itemTable[parsedData.item], {
            string = itemString,
            attributes = parsedData.attributes,
            count = count,
            toggle = false,
            key = parsedData.item
        })
    else
        -- modify itemTable
        if count then
            itemTable[key][index].count = itemTable[key][index].count + count
            if itemTable[key][index].count < 1 then
                table.remove(itemTable[key], index)
            end
        end
    end

    return itemTable
end

function Utility.ModifyMcItemInTable(itemString, itemTable, toggle)
    -- Parse the item string
    local parsedData = Utility.ParseMcItemString(itemString)
    local itemTable = itemTable or {}
    -- Check if the entry exists in the table
    local exists = false
    local key, index = nil, nil
    for k, items in pairs(itemTable) do
        if k == parsedData.item then
            for i, item in pairs(items) do
                if item.string == itemString then
                    exists = true
                    key, index = k,i
                    break
                end
            end
            if exists then break end
        end
    end
    --print(itemTable[key][index].toggle)
    if not exists then
        -- Add to dataTable
        print("no item in table, itemstring: ", itemString)
    else
        -- modify itemTable
        if toggle ~= nil then
            --print(itemTable[key][index].toggle)
            itemTable[key][index].toggle = toggle
            --print(itemTable[key][index].toggle)
        end
    end

    return itemTable
end

return Utility