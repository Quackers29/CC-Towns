local Manager = {}
local Utility = require("Utility")

local x,y,z = gps.locate()
--local INx,INy,INz = x-1,y,z
--local EXPx,EXPy,EXPz = x-1,y+2,z
local headers = {"id", "count", "toggle"}
local cloneHeight = -64 -- where to place the clone chest, -64 is in the bedrock layer just before the void
local timerSleep = 1


function Manager.isFileInUse(filename)
    local file = io.open(filename, "a+") -- Try to open the file in write mode
    if file then
        file:close() -- Close the file immediately if opened successfully
        return false -- File is not in use
    else
        return true -- File is in use (locked)
    end
end

-- Function to write data to a CSV file with a tab delimiter
function Manager.writeCSV(filename, data)
    local file = io.open(filename, "w+") -- Open the file in write mode
    if file then
        -- Write header row
        file:write(table.concat(headers, "\t") .. "\n")
        for _, row in ipairs(data) do
            local rowData = {}
            for _, header in ipairs(headers) do
                local value = tostring(row[header])
                local needCheck = type(value) == "string"
                if needCheck then
                    if not value:match('^".*"$') and value:match('\\"') then
                        value = tostring(value):gsub('\\"', '""')
                        value = '"'..value..'"'
                    else
                        value = tostring(value):gsub('\\"', '""')                    
                    end
                end
                table.insert(rowData,value)
            end
            file:write(table.concat(rowData, "\t") .. "\n")
        end
        file:close() -- Close the file when done
    else
        print("Error: Write, Unable to open the file.")
    end
end

-- Function to read data from a CSV file into a 2D array with a tab delimiter and handle Excel's escaped double quotes
function Manager.readCSV(filename)
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

function Manager.mergetable(main,secondary) --UNUSED
    if main ~= nil then
        for si,sv in pairs(secondary) do
            local checkFlag = false
            for mi,mv in pairs(main) do
                if mv.id == sv.id then
                    for i,v in pairs(sv) do
                        if i == "toggle" then
                            -- Only update toggle if it exists in updateTable (sv)
                            if sv.toggle ~= nil then
                                mv.toggle = sv.toggle
                            end
                        elseif i == "count" then
                            mv.count = mv.count + sv.count
                        end
                    end
                    checkFlag = true
                    break
                end
            end
            if checkFlag == false then
                local input ={}
                input["id"] = sv.id
                input["count"] = sv.count
                input["toggle"] = false
                table.insert(main,input)
            end
        end
    else
        main = secondary
    end
	return main
end

function Manager.outputItems(filename,itemString,EXPx,EXPy,EXPz)
	local r1,r2 = commands.data.get.block(EXPx,EXPy,EXPz)
	local r3 = string.find(r2[1],"Items: %[%]")
	if r1 == true then
		if r3 ~= nil then
			local resTable = Utility.readJsonFile(filename)
			if resTable ~= {} then
				local flag = true
				local outputID = ""
				local outputTag = ""
				local count = 0
				if resTable[itemString] then
                    local item = resTable[itemString]
                    while flag do
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
                        else
                            count = item.count
                            item.count = 0
                            if item.toggle == false or item.toggle == "false" then
                                resTable[itemString] = nil
                            end
                            resTable[itemString] = nil  -- removes infinite toggle on for now
                        end
                        flag = false
                    end
                end
                if flag == false then
                    Utility.writeJsonFile(filename, resTable)
                    local temp = ""
                    if outputTag ~= "" then
                        temp = (string.format('{Slot:%sb,id: "%s",Count: %sb,tag: {%s}}',0,outputID,count,outputTag))
                    else
                        temp = (string.format('{Slot:%sb,id: "%s",Count: %sb}',0,outputID,count))
                    end
                    local export = "Items set value ["..temp.."]"
                    commands.data.modify.block(EXPx,EXPy,EXPz, export)
                    
                end
			end
		end
	end
end

function Manager.removeFirstLevelBrackets(input)
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

function Manager.checkItems(filePath,OUTx,OUTy,OUTz)
    local resTable = Utility.readJsonFile(filePath)
    if resTable then
        for key,item in pairs(resTable) do
            if item.toggle == true or item.toggle == "true" then
                if item.count > 0 then
                    Manager.outputItems(filePath,key,OUTx,OUTy,OUTz)
                end
            end
        end
    end
end

local scrollTimerID = os.startTimer(timerSleep) -- Timer triggers every x seconds for scrolling

function Manager.handleTimer()
    scrollTimerID = os.startTimer(timerSleep) -- Reset the timer to x seconds
end

function Manager.inputItems(filename,INx,INy,INz)
	local itemTable = Utility.readJsonFile(filename)
	local INq,INw = commands.data.get.block(INx,INy,INz,"Items")
	if INq then
		-- Move chest using clone to preserve contents when reading it. 
        commands.clone(INx,INy,INz,INx,INy,INz,INx,cloneHeight,INz, "replace", "move")
        local INa,INb = commands.data.get.block(INx,cloneHeight,INz,"Items")
		commands.data.modify.block(INx,cloneHeight,INz, "Items set value []")
        commands.clone(INx,cloneHeight,INz,INx,cloneHeight,INz,INx,INy,INz, "replace", "move")

		local output = Manager.removeFirstLevelBrackets(INb[1])
		for _, k in ipairs(output) do
			local slot = string.match(k,"Slot: (%d+)")
			local id = string.sub(string.match(k,"id: (.-.),"),2,-2)
			local count = tonumber(string.match(k,"Count: (%d+)"))
			local tag = string.match(k,"tag: {(.*).")

			if tag ~= nil then
				id = id..","..tag
			end
            --start new parse here
            itemTable = Utility.AddMcItemToTable(id,itemTable,count)
		end
		Utility.writeJsonFile(filename, itemTable)
	end
end

return Manager
