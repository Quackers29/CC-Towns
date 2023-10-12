local Utility = {}

function Utility.readJsonFile(filePath)
    local file = fs.open(filePath, "r")

    if file then
        local serializedData = file.readAll()
        file.close()

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
    local file = fs.open(filePath, "w")

    if file then
        file.write(serializedData)
        file.close()
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
        mod, item = itemString:match("(.-):(.-)")
    end

    return {
        mod = mod,
        item = item,
        attributes = attributes or ""
    }
end

function Utility.AddMcItemToTable(itemString, itemTable, count)
    -- Parse the item string
    local parsedData = ParseMcItemString(itemString)

    -- Check if the entry exists in the table
    local exists = false
    for key, items in pairs(itemTable) do
        local index = nil
        if key == parsedData.item then
            for index, item in pairs(items) do
                if item.string == itemString then
                    exists = true
                    break
                end
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
                toggle = false
            })
        else
            -- modify itemTable
            if count then
                itemTable[key][index].count = itemTable[key][index].count + count
                if table[key][index].count < 1 then
                    table.remove(itemTable[key], index)
                end
            end
        end
    end
end

return Utility