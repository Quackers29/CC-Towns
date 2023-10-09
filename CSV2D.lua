local CSV2D = {}

-- Helper function to trim leading and trailing whitespaces
function CSV2D.trim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

function CSV2D.isKeyValueTable(t)
    if type(t) ~= "table" then return false end
    for k, _ in pairs(t) do
        if type(k) == "number" then
            return false
        end
    end
    return true
end

function CSV2D.readCSV2D(file)
    local data = {}
    local headers = nil
    local currentKey = nil
    local currentSubKey = nil
    local subTable = nil
    local isArrayField = false
    local currentSubKeyHeader = nil
    local miniTable = {}
    
    for line in io.lines(file) do
        --print("Processing line: " .. line)
        local row = {}
        local columnIndex = 1
        --os.sleep(1)
        
        for value in string.gmatch(line .. "\t", "(.-)\t") do
            value = CSV2D.trim(value)  -- Trim spaces from the value

            if type(value) ~= "table" then
                -- Convert the value to number if it's a number, otherwise keep it as a string
                local escapedValue = tostring(value):gsub('""', '\\"') -- Escape tab characters if found
                -- Check if the input string has encapsulated quotes and remove them
                local outputString = escapedValue:match('^"(.*)"$') or escapedValue
                local numValue = tonumber(value)
                local boolValue = value:lower()
                if boolValue == "true" then
                    value = true
                elseif boolValue == "false" then
                    value = false
                elseif numValue then
                    value = numValue
                else
                    value = outputString
                end
            end
            
            if not headers then
                row[columnIndex] = value
            else
                local header = headers[columnIndex]
                if header == "key" and value ~= "" then
                    if currentKey then
                        for k, v in pairs(subTable) do
                            miniTable[k] = v
                        end
                        data[currentKey] = miniTable
                        currentKey = nil
                        subTable = nil
                        --print("Data for key added to main table.")
                        miniTable = {}
                    end
                    --print("Found key: " .. value)
                    currentKey = value
                    subTable = {}
                    isArrayField = false
                elseif string.match(header, ":key$") and value ~= "" then
                    --print("Found subKey under header " .. header .. ": *" .. value.."*")
                    currentSubKey = value
                    currentSubKeyHeader = string.gsub(header, ":key$","")
                elseif currentSubKey then
                    subTable[currentSubKeyHeader] = subTable[currentSubKeyHeader] or {}
                    subTable[currentSubKeyHeader][currentSubKey] = subTable[currentSubKeyHeader][currentSubKey] or ""
                    subTable[currentSubKeyHeader][currentSubKey] = value
                    --print("Added value to subKey " .. currentSubKey .. ": " .. value)
                    currentSubKey = nil
                elseif isArrayField and value ~= "" then
                    table.insert(miniTable[header], value)
                    --print("Appended to array under header " .. header .. ": " .. value)
                elseif currentKey and value ~= "" then
                    if miniTable[header] then
                        miniTable[header] = {miniTable[header]}
                        isArrayField = true
                        table.insert(miniTable[header], value)
                        --print("Converted to array and added value under header " .. header .. ": " .. value)
                    else
                        miniTable[header] = value
                        isArrayField = false
                        --print("Added value under header " .. header .. ": *" .. value.."*")
                    end
                end
            end
            columnIndex = columnIndex + 1
        end
        
        if not headers then
            headers = row
            --print("Headers set.")
        elseif currentKey and not next(subTable) then

            
            currentKey = nil
            subTable = nil
            --print("Data for key added to main table.")
        end
    end

    if next(miniTable) then
        for k, v in pairs(subTable) do
            miniTable[k] = v
        end
        data[currentKey] = miniTable    
    end

    print("Parsing completed.")
    return data
end
      

local data = {
    Logging_upgrade = {
        Cost = {Wood = 100, Iron = 5},
        Prerequisites = {"Forestry", "Production1", "Production2"},
        Duration = 5
    },
    Logging_upgrade2 = {
        Cost = {Wood = 100, Iron = 5},
        Prerequisites = {"Forestry", "Production1", "Production2"},
        Duration = 5
    },
    -- ... (other data)
}


function CSV2D.writeCSV2D(data, filename)
    local file = io.open(filename, "w")

    -- Helper function to determine if a value is a key-value table
    local function isKeyValueTable(t)
        if type(t) ~= "table" then return false end
        for k, _ in pairs(t) do
            if type(k) == "number" then
                return false
            end
        end
        return true
    end

    -- Write headers
    local headers = {"key"}
    for _, values in pairs(data) do
        for subKey, _ in pairs(values) do
            if not table.contains(headers, subKey) then
                if isKeyValueTable(values[subKey]) then
                    table.insert(headers, subKey .. ":key")
                    table.insert(headers, subKey)
                else
                    table.insert(headers, subKey)
                end
            end
        end
    end
    file:write(table.concat(headers, "\t") .. "\n")


    -- Write data
    for key, values in pairs(data) do
        local maxRows = 1
        local holdkeyValue = nil
        for _, v in pairs(values) do
            if type(v) == "table" then
                maxRows = math.max(maxRows, #v)
            end
        end

        for i = 1, maxRows do
            local rowData = {key}   
            if i == 1 then
                rowData = {key}      
            else
                rowData = {""}         
            end

            for j = 2, #headers do
                local header = headers[j]
                local value = values[header]
                local value2 = values[string.gsub(header,":key$","")]
                if isKeyValueTable(value2) and not holdkeyValue then
                    local ix = 1
                    local k,y = nil,nil
                    for a, b in pairs(value2) do
                        if ix == i then
                            k,y = a,b
                        end
                        ix = ix + 1
                    end
                    table.insert(rowData, k or "")
                    holdkeyValue = y
                elseif holdkeyValue then
                    table.insert(rowData, holdkeyValue)
                    holdkeyValue = nil
                elseif type(value) == "table" then
                    table.insert(rowData, tostring(value[i]) or "")
                else
                    table.insert(rowData, (i == 1) and tostring(value) or "")
                end
            end
            file:write(table.concat(rowData, "\t") .. "\n")
        end
    end

    file:close()
end

-- A utility function to check if a value exists in a table
function table.contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

--CSV2D.writeComplexCSV(data, "output.txt")

--b = CSV2D.parseComplexCSV(file)


return CSV2D