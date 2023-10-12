local Utility = {}

function ParseMcItemString(itemString)
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

function AddMcItemToTable(itemString, itemTable, count)
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