-- Monitor.lua
local Utility = require("Utility")

local Monitor = {}
local monitor
local buttons = {} -- Table to store drawn buttons

local GAP = 4 -- This will add a space between buttons and wall
local ListOffset = {}
local maxButtonsPerPage

function Monitor.init()
    monitor = peripheral.find("monitor")
    --if not monitor then
    --    error("Monitor not found!")
    --end
    while not monitor then
        print("Waiting for Monitor")
        monitor = peripheral.find("monitor")
        os.sleep(5)
    end
end

-- Function to clear the monitor and set the cursor position
function Monitor.clear()
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

-- Function to write text on the monitor
function Monitor.write(text, x, y, color)
    local color = color or colors.white
    monitor.setCursorPos(x, y)
    monitor.setTextColor(color)
    monitor.write(text)
end

-- New function to return monitor size
function Monitor.getSize()
    return monitor.getSize()
end

local function cloneTable(t)
    local newTable = {}
    for k, v in pairs(t) do
        newTable[k] = v
    end
    return newTable
end

-- New function to return monitor size
function Monitor.OffsetButton(x,y)
    local ListIndex = y or 0
    if x == 0 then
        ListOffset[ListIndex] = 0
    else
        if ListOffset[ListIndex] > 0 or x > 0 then
            ListOffset[ListIndex] = ListOffset[ListIndex] + x
        end
    end
end

-- New function to return monitor size
function Monitor.PrevButton(y)
    local currentOffset = y or 0
    if currentOffset > 0 then
        currentOffset = currentOffset -1
    end
end

function Monitor.displayMap(towns, currentTown, topLeftX, topLeftY, mapWidth, mapHeight, zoom)
    local centerX = topLeftX + math.floor(mapWidth / 2)
    local centerY = topLeftY + math.floor(mapHeight / 2)
    
    -- Clear previous drawings and set background
    --monitor.setBackgroundColor(colors.black)

    -- Plot each town relative to the current town's centered position
    for _, town in pairs(towns) do
        local relX = math.floor((town.x - currentTown.x) / zoom)
        local relZ = math.floor((currentTown.z - town.z) / zoom)

        local screenX = centerX + relX
        local screenZ = centerY - relZ

        if screenX >= topLeftX and screenX < (topLeftX + mapWidth) and screenZ >= topLeftY and screenZ < (topLeftY + mapHeight) then
            monitor.setCursorPos(screenX, screenZ)
            monitor.setTextColor(colors.blue)
            monitor.write("T") -- representing a town
        end
    end

    -- Plot the current town at the center
    monitor.setCursorPos(centerX, centerY)
    monitor.setTextColor(colors.red)
    monitor.write("X") -- representing current town
end


-- Function to draw a button with an outline
function Monitor.drawPushButton(text, identifier, x, y, width, height)
    -- Drawing the button box with an outline
    for i = x, x+width+1 do
        for j = y, y+height+1 do
            monitor.setCursorPos(i, j)
            -- Drawing the corners
            if (i == x and j == y) or (i == x+width+1 and j == y) or (i == x and j == y+height+1) or (i == x+width+1 and j == y+height+1) then
                monitor.write("+")
            -- Drawing the top and bottom edges
            elseif (i > x and i < x+width+1) and (j == y or j == y+height+1) then
                monitor.write("-")
            -- Drawing the left and right edges
            elseif (j > y and j < y+height+1) and (i == x or i == x+width+1) then
                monitor.write("|")
            -- Filling the center
            else
                monitor.write(" ")
            end
        end
    end
    -- Writing the text in the middle of the button
    local textX = x + 1 + math.floor((width - #text) / 2) -- Adjusted for outline
    local textY = y + 1 + math.floor(height / 2)          -- Adjusted for outline
    Monitor.write(text, textX, textY)
end

function Monitor.drawOldButton(text, icon, identifier, x, y, justify)
    -- Icon is expected to be a single character
    local buttonText = "[ " .. icon .. " ]"
    
    if justify == "right" then
        monitor.setCursorPos(x, y)
        monitor.write(text .. " " .. buttonText)
    else -- default to left if not explicitly set to right
        monitor.setCursorPos(x, y)
        monitor.write(buttonText .. " " .. text)
    end

    local buttonWidth = #buttonText
end

function Monitor.drawFlexibleGrid(startX, startY, endX, endY, minWidth, minHeight, buttonsx)
    local ListIndex = 0
    ListOffset[ListIndex] = ListOffset[ListIndex] or 0
    local currentOffset = ListOffset[ListIndex]
    buttons = {}
    -- Filter for only 'push' type buttons
    local pushButtons = {}
    for _, button in ipairs(buttonsx) do
        if button.type == "push" then
            table.insert(pushButtons, button)
        end
    end

    -- Calculate total available space
    local totalWidth = endX - startX
    local totalHeight = endY - startY
    
    -- Calculate maximum rows and columns based on button sizes and gaps
    local cols = math.floor((totalWidth + GAP) / (minWidth + GAP))
    local rows = math.floor((totalHeight + GAP) / (minHeight + GAP))

    maxButtonsPerPage = rows * cols

    -- Adjust button sizes if necessary
    local buttonWidth = math.floor((totalWidth + GAP) / cols) - GAP
    local buttonHeight = math.floor((totalHeight + GAP) / rows) - GAP
    
    -- Adjusting for Prev and Next buttons if needed
    local availableSlots = maxButtonsPerPage
    if maxButtonsPerPage < #pushButtons then
        availableSlots = availableSlots - 2
    end
    local needsPrevNext = maxButtonsPerPage < #pushButtons
    local maxOffset = #pushButtons - maxButtonsPerPage + 2

    local endingButtonIndex = math.min(currentOffset + availableSlots, #pushButtons)

    -- Loop to draw the buttons
    local xOffset = startX
    local yOffset = startY

    for i = currentOffset + 1, endingButtonIndex do
        local button = pushButtons[i]
        Monitor.drawPushButton(button.label, button.id, xOffset, yOffset, buttonWidth, buttonHeight)

        -- Store the button's position for future reference
        button.positions = {startX = xOffset,endX = xOffset + buttonWidth,startY = yOffset,endY = yOffset + buttonHeight}
        buttons[button.id] = button
        
        -- Move to the next position
        xOffset = xOffset + buttonWidth + GAP
        if xOffset + buttonWidth > endX then
            xOffset = startX
            yOffset = yOffset + buttonHeight + GAP
        end
    end

    -- Draw Prev button if not at the start
    if needsPrevNext then
        if currentOffset > 0 then
            Monitor.drawPushButton("Prev", "Prev", xOffset, yOffset, buttonWidth, buttonHeight) 
            -- Handle click event to decrease currentOffset and redraw
            local positions = {startX = xOffset,endX = xOffset + buttonWidth,startY = yOffset,endY = yOffset + buttonHeight}
            buttons["Prev"] = {positions = positions,enabled = true,page = "all",action = function() OffsetButton(-1) end}

            xOffset = xOffset + buttonWidth + GAP
            if xOffset + buttonWidth > endX then
                xOffset = startX
                yOffset = yOffset + buttonHeight + GAP
            end
        else
            xOffset = xOffset + buttonWidth + GAP
            if xOffset + buttonWidth > endX then
                xOffset = startX
                yOffset = yOffset + buttonHeight + GAP
            end
        end
    end
    
    -- Draw Next button if there are more buttons to show after this page
    if needsPrevNext then
        if currentOffset < maxOffset then
            Monitor.drawPushButton("Next","Next", xOffset, yOffset, buttonWidth, buttonHeight)
            -- Handle click event to increase currentOffset and redraw
            local positions = {startX = xOffset,endX = xOffset + buttonWidth,startY = yOffset,endY = yOffset + buttonHeight}
            buttons["Next"] = {positions = positions,enabled = true,page = "all",action = function() OffsetButton(1) end}      
        end
    end
end

function Monitor.isInsideButton(x, y)
    for _, button in pairs(buttons) do
        local pos = button.positions
        --print(button.id,pos.startX,pos.endX, pos.startY, pos.endY)
        --os.sleep(0.3)
        if pos and x >= pos.startX and x <= pos.endX and y >= pos.startY and y <= pos.endY then
            return true, button
        end
    end
    return false, nil
end

function Monitor.ClearButtons()
    buttons = {}
end

function Monitor.OffsetCheck(v, endi)
    if v > 0 then
        v = v + 1
    elseif v < 0 then
        v = endi + v
    else
        v = 1
    end
    return v
end

function Monitor.drawList(startY, endY, items, buttonsConfig, rowHeight, ListIndex)
    local ListIndex = ListIndex or 0
    ListOffset[ListIndex] = ListOffset[ListIndex]
    local currentOffset = ListOffset[ListIndex]
    rowHeight = rowHeight or 1
    local maxX, maxY = Monitor.getSize()
    local visibleItems = math.floor((endY - startY) / rowHeight)
    local endingItemIndex = currentOffset + visibleItems - 1
    if endingItemIndex > #items then
        endingItemIndex = #items
    end

    -- Draw Scroll Up button
    local sButton = {id = "ScrollUp",width = 3,colorOn = colors.yellow,colorOff = colors.gray,charOn = "^",action = function() OffsetButton(-1) end,enabled = true, type = list}
    Monitor.drawButton(1, startY, sButton)
    Monitor.write("+"..tostring(currentOffset), 1 + sButton.width + 1, startY)

    -- Draw items based on currentOffset
    -- First sort the items by count (decreasing)
    local function compare(a, b)
        return a.count > b.count
    end
    table.sort(items,compare)

    for i = currentOffset + 1, endingItemIndex do
        local item = items[i]
        local currentY = startY + 1 + (i - currentOffset - 1) * rowHeight
        
        local xLeftOffset = 1
        local xRightOffset = maxX
        local output = {}
        -- Draw associated buttons for this row and adjust offsets
        for _, btn in ipairs(buttonsConfig) do
            output = btn
            if item[btn.id] ~= nil then
                local was = btn.enabled
                output.enabled = item[btn.id]
                output.item = item
            end
            if btn.justify == "left" then
                Monitor.drawButton(xLeftOffset, currentY, output)
                xLeftOffset = xLeftOffset + btn.width + 1
            elseif btn.justify == "right" then
                Monitor.drawButton(xRightOffset - btn.width + 1, currentY, output)
                xRightOffset = xRightOffset - btn.width - 1
            end
        end
        
        -- Draw the item text based on the new offsets
        monitor.setTextColor(colors.white)
        local itemD = item.count.."x "..item.key
        Monitor.write(string.sub(itemD,1,xRightOffset - xLeftOffset), xLeftOffset, currentY)

    end

    -- Draw Scroll Down button
    local sButton = {id = "ScrollDown",width = 3,colorOn = colors.yellow,colorOff = colors.gray,charOn = "v",action = function() OffsetButton(1) end,enabled = true, type = list}
    Monitor.drawButton(1, endY - rowHeight + 1, sButton)
    Monitor.write("+"..tostring(math.max(#items-visibleItems-currentOffset+1,0)), 1 + sButton.width + 1, endY - rowHeight + 1)
end

-- UPDATE, Merge buttonConfig and items together at the SOURCE, per item there is an array of buttons, so that the buttons can be enabled BEFORE here
function Monitor.drawKeyList(startY, endY, items, buttonsConfig, rowHeight, ListIndex)
    local ListIndex = ListIndex or 0
    ListOffset[ListIndex] = ListOffset[ListIndex] or 0
    local currentOffset = ListOffset[ListIndex]
    rowHeight = rowHeight or 1
    local maxX, maxY = Monitor.getSize()
    local visibleItems = math.floor((endY - startY) / rowHeight)
    local endingItemIndex = currentOffset + visibleItems - 1
    if endingItemIndex > Utility.getArraySize(items) then
        endingItemIndex = Utility.getArraySize(items)
    end

    -- Draw Scroll Up button
    local sButton = {id = "ScrollUp",width = 3,colorOn = colors.yellow,colorOff = colors.gray,charOn = "^",action = function() OffsetButton(-1,ListIndex) end,enabled = true, type = list}
    Monitor.drawButton(1, startY, sButton)
    Monitor.write("+"..tostring(currentOffset), 1 + sButton.width + 1, startY)

    -- Draw items based on currentOffset
    for i = currentOffset + 1, endingItemIndex do
        local indexKey = 1
        local item = nil
        for key, value in pairs(items) do
            if i == indexKey then
                value["key"] = key
                item = value
            end
            indexKey = indexKey + 1
        end

        local currentY = startY + 1 + (i - currentOffset - 1) * rowHeight
        local xLeftOffset = 1
        local xRightOffset = maxX
        local output = {}
        -- Draw associated buttons for this row and adjust offsets
        if buttonsConfig then
            for _, btn in ipairs(buttonsConfig) do
                output = btn
                output.item = item
                if item[btn.id] ~= nil then
                    local was = btn.enabled
                    output.enabled = item[btn.id]
                    --print(btn.id, item[btn.id] ,output.enabled)
                end
                if btn.justify == "left" then
                    Monitor.drawButton(xLeftOffset, currentY, output)
                    xLeftOffset = xLeftOffset + btn.width + 1
                elseif btn.justify == "right" then
                    Monitor.drawButton(xRightOffset - btn.width + 1, currentY, output)
                    xRightOffset = xRightOffset - btn.width - 1
                end
            end
        end
        
        -- Draw the item text based on the new offsets
        monitor.setTextColor(colors.white)
        local extra = item.extra or ""
        local itemD = item.key..extra
        Monitor.write(string.sub(itemD,1,xRightOffset - xLeftOffset), xLeftOffset, currentY)

    end

    -- Draw Scroll Down button
    local sButton = {id = "ScrollDown",width = 3,colorOn = colors.yellow,colorOff = colors.gray,charOn = "v",action = function() OffsetButton(1, ListIndex) end,enabled = true, type = list}
    Monitor.drawButton(1, endY - rowHeight + 1, sButton)
    Monitor.write("+"..tostring(math.max(#items-visibleItems-currentOffset+1,0)), 1 + sButton.width + 1, endY - rowHeight + 1)
end



function Monitor.drawButton(x, y, button)
    local positions = {}
    local buttonConfig = cloneTable(button)
    local id = buttonConfig.id.."x"..tostring(x).."y"..tostring(y)
    local width = buttonConfig.width or 3
    local colorOn = buttonConfig.colorOn or colors.white
    local colorOff = buttonConfig.colorOff or colors.gray
    local charOn = buttonConfig.charOn or " "
    local action = buttonConfig.action
    local enabled = buttonConfig.enabled
    local charToDisplay = " "
    local colorToUse = colors.gray
    
    if enabled then
        charToDisplay = charOn
        colorToUse = colorOn
    else
        charToDisplay = " "
        colorToUse = colorOff
    end

    --print(buttonConfig.enabled, charToDisplay)
    --local charToDisplay = (enabled == true) and charOn or " "
    local text = "[" .. string.rep(" ", math.floor((width - 3)/2)) .. charToDisplay .. string.rep(" ", math.ceil((width - 3)/2)) .. "]"

    monitor.setBackgroundColor(colors.black) -- You can change this to whatever background color you want
    Monitor.write(text, x, y, colorToUse)

    -- Saving the button details for later interactions
    positions = {startY = y,endY = y, startX = x,endX = x + width - 1}
    buttonConfig.positions = positions
    buttons[id] = buttonConfig
    --print("Y MIDDLE: "..buttons[id].positions.endY.."\n")
end

return Monitor
