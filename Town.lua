local x,y,z = gps.locate()
local INx,INy,INz = x-1,y,z
local EXPx,EXPy,EXPz = x-1,y+2,z
local debugSleep = 0
local filePath = "RES_X"..x.."Y"..y.."Z"..z..".txt"
local headers = {"id", "count", "toggle"}
local cloneHeight = -64 -- where to place the clone chest, -64 is in the bedrock layer just before the void
local timerSleep = 1

-- Loads the switch definition from a serialized table.
local function debug()
	sleep(debugSleep)
end

local function isFileInUse(filename)
    local file = io.open(filename, "a+") -- Try to open the file in write mode
    if file then
        file:close() -- Close the file immediately if opened successfully
        return false -- File is not in use
    else
        return true -- File is in use (locked)
    end
end

-- Function to write data to a CSV file with a tab delimiter
local function writeCSV(filename, data)
    --local quotingChar = '"' -- Use double quote as the quoting character
    local file = io.open(filename, "w") -- Open the file in write mode
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
        --print("CSV file created successfully.")
    else
        print("Error: Unable to open the file.")
    end
end

-- Function to read data from a CSV file into a 2D array with a tab delimiter and handle Excel's escaped double quotes
local function readCSV(filename)
    local data = {} -- Initialize the 2D array
    local file = io.open(filename, "r") -- Open the file in read mode

    local headerRow = file:read("*line")
    if file and headerRow ~= nil then
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
                
                
                --print(value)

                -- Convert the value to number if it's a number, otherwise keep it as a string
                local escapedValue = tostring(value):gsub('""', '\\"') -- Escape tab characters if found
                -- Check if the input string has encapsulated quotes and remove them
                local outputString = escapedValue:match('^"(.*)"$') or escapedValue
                local numValue = tonumber(value)
                local boolValue = value:lower()
                if boolValue == "true" or boolValue == "false" then
                    row[headers[count]] = boolValue
                elseif numValue then
                    row[headers[count]] = numValue
                else
                    row[headers[count]] = outputString
                end
                --print("done")
                count = count + 1
            end
            table.insert(data, row) -- Add the row to the 2D array
        end
        file:close() -- Close the file when done
    else
        print("Error: Unable to open the file.")
    end

    return data
    
end

local function mergetable(main,secondary)
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
            --print("Main[id] "..tostring(si))
        end
    end
    for _, row in ipairs(main) do
        --print(table.concat(row, " * \t * "))
    end
	return main
end

local function inputItems(filename)
	local prevtable = readCSV(filename)
	local INq,INw = commands.data.get.block(INx,INy,INz,"Items")
	if INq then
		-- Move chest using clone to preserve contents when reading it. 
        commands.clone(INx,INy,INz,INx,INy,INz,INx,(cloneHeight),INz, "replace", "move")
        local INa,INb = commands.data.get.block(INx,(cloneHeight),INz,"Items")
		commands.data.modify.block(INx,(cloneHeight),INz, "Items set value []")
        commands.clone(INx,(cloneHeight),INz,INx,(cloneHeight),INz,INx,INy,INz, "replace", "move")

		local ytable = {}
		
		local output = removeFirstLevelBrackets(INb[1])
		for _, k in ipairs(output) do
			local slot = string.match(k,"Slot: (%d+)")
			local id = string.sub(string.match(k,"id: (.-.),"),2,-2)
			local count = tonumber(string.match(k,"Count: (%d+)"))
			local tag = string.match(k,"tag: {(.*).")
            local input ={}
            local saveFlag = false

			if tag ~= nil then
				id = id..","..tag
			end
            input["id"] = id
            --input["toggle"] = false
            --print(id)
            if ytable ~= nil then
                for i,v in pairs(ytable) do
                    if v.id == id then
                        ytable[i].count = ytable[i]+count
                    else
                        input["count"] = count
                        saveFlag = true
                    end
                end
                if saveFlag == true then
                    table.insert(ytable,input)
                else
                    input["count"] = count
                    table.insert(ytable,input)
                end
            end
		end
        --for _, row in ipairs(ytable) do
        --    print("id:", row["id"], "count:", row["count"])
        --end
		if ytable ~= {}	then
			writeCSV(filename, mergetable(prevtable,ytable))
		end
	end
end

local function outputItems(filename,item)
	local r1,r2 = commands.data.get.block(EXPx,EXPy,EXPz)
	local r3 = string.find(r2[1],"Items: %[%]")
	if r1 == true then
		if r3 ~= nil then
			local prevtable = readCSV(filename)
			if prevtable ~= {} then
				local flag = true
				local outputID = ""
				local outputTag = ""
				local count = 0
				for i,v in pairs(prevtable) do
                    if v.id == item then
                        while flag do
                            local flagTag = string.match(v.id,"(.-.),")
                            if flagTag ~= nil then
                                outputTag = string.match(v.id,',(.*)')
                                outputID = flagTag
                            else
                                outputID = v.id
                                outputTag = nil
                            end
                            if v.count > 64 then
                                v.count = v.count-64
                                count = 64
                            else
                                count = v.count
                                v.count = 0
                                if v.toggle == false or v.toggle == "false" then
                                    table.remove(prevtable,i)
                                end
                                table.remove(prevtable,i)  -- removes infinite toggle on for now
                            end
                            flag = false
                        end
                    end
                end
                if flag == false then
                    writeCSV(filename, prevtable)
                    local temp = ""
                    if outputTag ~= nil then
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

function removeFirstLevelBrackets(input)
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

local function checkItems(filePath)
    local prevtable = readCSV(filePath)
    for i,v in pairs(prevtable) do
        if v.toggle == true or v.toggle == "true" then
            if v.count > 0 then
                outputItems(filePath,prevtable[i].id)
            end
        end
    end
    
end

-- Open a connection to the first available monitor
local monitor = peripheral.find("monitor")



local scrollTimerID = os.startTimer(timerSleep) -- Timer triggers every 1 second for scrolling

local function handleTimer()
    scrollTimerID = os.startTimer(timerSleep) -- Reset the timer to 5 seconds
end

-- Check if a monitor is connected
if monitor then
    -- Set the text size and color
    monitor.setTextScale(1)
    monitor.setTextColor(colors.green) -- You can change the color by specifying a different color code

    -- Display the rolling greeting message
    local rollingGreeting = "Hello, World! Click the button to execute a function."
    local screenWidth, screenHeight = monitor.getSize()
    local buttonWidth = 3
    local buttonHeight = 3
    local buttonX = 1 --math.floor((screenWidth - buttonWidth) / 2)
    local scrollUpButtonY = 2
    local scrollDownButtonY = screenHeight
    local buttonYSpacing = 1

    -- Variables for scrolling
    local scrollOffset = 1
    local arrayScrollOffset = 1
    

    -- Function to draw a button
    local function drawButton(label, x, y, width, toggle, togChar)
        monitor.setCursorPos(x, y)
        local toggler = " "
        if toggle == true or toggle == "true" then
            toggler = togChar
        end
        monitor.write("[" .. toggler .. "]"..label .. string.rep(" ", width - string.len(label) - 2))
    end

    -- Main loop
    while true do
        local x = false
        if isFileInUse(filePath) then --
            os.sleep(1)
        else

            local prevtable = readCSV(filePath)
            monitor.clear()

            -- Draw the rolling greeting message on the first line and scroll it
            local visibleGreeting = string.sub(rollingGreeting, scrollOffset, scrollOffset + screenWidth - 1)
            monitor.setCursorPos(1, 1)
            monitor.write(visibleGreeting .. string.rep(" ", screenWidth - string.len(visibleGreeting)))

            -- Draw scroll-up button
            drawButton("----Scroll Up----  +"..tostring(arrayScrollOffset-1), buttonX, scrollUpButtonY, buttonWidth, true, "^")

            local displayTable = {}
            for i,v in pairs(prevtable) do
                if v.count > 0 then
                    table.insert(displayTable,v)
                end
            end
            -- Draw buttons for visible array items
            for i,v in pairs(displayTable) do
                if i >= arrayScrollOffset and i < arrayScrollOffset + screenHeight - 3 then
                    drawButton(v.count.."x "..string.sub(v.id, string.find(v.id, ":") + 1), buttonX, scrollUpButtonY + (i - arrayScrollOffset + 1) * buttonYSpacing, buttonWidth, v.toggle, "O")
                end
            end

            -- Draw scroll-down button
            drawButton("----Scroll Down----  +"..tostring(math.max(#displayTable - arrayScrollOffset - screenHeight + 4,0)), buttonX, scrollDownButtonY, buttonWidth, true, "v")

            -- Wait for an event
            local event, param1, param2, param3, param4 = os.pullEvent()

            -- Check if the timer event occurred for scrolling
            if event == "timer" and param1 == scrollTimerID then
                inputItems(filePath)
                checkItems(filePath)
                
                -- Scroll the rolling greeting message
                scrollOffset = scrollOffset + 1
                if scrollOffset > string.len(rollingGreeting) then
                    scrollOffset = 1
                end
                -- Restart the timer for continuous scrolling
                handleTimer()
            elseif event == "monitor_touch" then
                local x, y = param2, param3
                -- Check if a button is clicked
                if x >= buttonX and x <= buttonX + buttonWidth - 1 then
                    -- Check if the scroll-up button is clicked
                    if y == scrollUpButtonY then
                        -- Scroll up logic here
                        if arrayScrollOffset > 1 then
                            arrayScrollOffset = arrayScrollOffset - 1
                        end
                    -- Check if the scroll-down button is clicked
                    elseif y == scrollDownButtonY then
                        -- Scroll down logic here
                        if arrayScrollOffset < #displayTable - screenHeight + 4 then
                            arrayScrollOffset = arrayScrollOffset + 1
                        end
                    elseif y >= 2 and y <= (scrollDownButtonY - 1) then
                        local index = (y + arrayScrollOffset - 3)
                        if index <= #displayTable then
                            local selectedItem = displayTable[(y + arrayScrollOffset - 3)].id
                            local selectedToggle = false
                            if displayTable[(y + arrayScrollOffset - 3)].toggle == false or displayTable[(y + arrayScrollOffset - 3)].toggle == "false" then
                                selectedToggle = true
                            end
                            --print(selectedItem,selectedToggle)
                            monitor.setCursorPos(1, screenHeight)
                            monitor.clearLine()
                            monitor.write("Button: " .. selectedItem)
                            
                            local xtable = {}
                            local ytable = {}
                            ytable["id"] = selectedItem
                            ytable["toggle"]  = selectedToggle
                            table.insert(xtable,ytable)
                            writeCSV(filePath, mergetable(prevtable,xtable))
                            --os.sleep(1) -- Pause for 1 second to display the result before clearing the screen
                        end
                    end
                end
                handleTimer()
            end
        end
    end
else
    print("No monitor found. Please attach a monitor and run the program again.")
end