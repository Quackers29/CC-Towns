-- Monitor.lua

local Monitor = {}
local monitor
local buttons = {} -- Table to store drawn buttons

local GAP = 4 -- This will add a space between buttons and wall
local currentOffset = 0
local maxButtonsPerPage

function Monitor.init()
    monitor = peripheral.find("monitor")
    if not monitor then
        error("Monitor not found!")
    end
end

-- Function to clear the monitor and set the cursor position
function Monitor.clear()
    monitor.clear()
    monitor.setCursorPos(1, 1)
end

-- Function to write text on the monitor
function Monitor.write(text, x, y)
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

-- New function to return monitor size
function Monitor.getSize()
    return monitor.getSize()
end

-- New function to return monitor size
function Monitor.OffsetButton(x)
    if x == 0 then
        currentOffset = 0
    else
        if currentOffset > 0 or x > 0 then
            currentOffset = currentOffset + x
        end
    end
end

-- New function to return monitor size
function Monitor.PrevButton()
    if currentOffset > 0 then
        currentOffset = currentOffset -1
    end
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
        --table.insert(buttons, {
        --    name = identifier,
        --    x = x,
        --    y = y,
       --     width = width,
        --    height = height
        --})
    end

    -- Writing the text in the middle of the button
    local textX = x + 1 + math.floor((width - #text) / 2) -- Adjusted for outline
    local textY = y + 1 + math.floor(height / 2)          -- Adjusted for outline
    Monitor.write(text, textX, textY)
end

function Monitor.drawButton(text, icon, identifier, x, y, position)
    -- Icon is expected to be a single character
    local buttonText = "[ " .. icon .. " ]"
    
    if position == "right" then
        monitor.setCursorPos(x, y)
        monitor.write(text .. " " .. buttonText)
    else -- default to left if not explicitly set to right
        monitor.setCursorPos(x, y)
        monitor.write(buttonText .. " " .. text)
    end

    local buttonWidth = #buttonText
    --table.insert(buttons, {
    --    name = identifier,
    --    x = position == "right" and x + #text or x,
    --    y = y,
    --    width = buttonWidth,
    --    height = 1 -- Since it's a single line button
    --})
end

function Monitor.drawFlexibleGrid(startX, startY, endX, endY, minWidth, minHeight, buttonsx)
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
    --if currentOffset > 0 then
    --    availableSlots = availableSlots - 1
    --end
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
        button.positions = {
            startX = xOffset,
            endX = xOffset + buttonWidth,
            startY = yOffset,
            endY = yOffset + buttonHeight
        }
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
            local positions = {
                startX = xOffset,
                endX = xOffset + buttonWidth,
                startY = yOffset,
                endY = yOffset + buttonHeight,
            }
            buttons["Prev"] = {
                positions = positions,
                enabled = true,
                page = "all",
                action = function()
                    OffsetButton(-1)
                end
            }
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
            local positions = {
                startX = xOffset,
                endX = xOffset + buttonWidth,
                startY = yOffset,
                endY = yOffset + buttonHeight,
            }
            buttons["Next"] = {
                positions = positions,
                enabled = true,
                page = "all",
                action = function()
                    OffsetButton(1)
                end
            }      
        end
    end
end

function Monitor.isInsideButton(x, y)
    for _, button in pairs(buttons) do
        local pos = button.positions
        if pos and x >= pos.startX and x <= pos.endX and y >= pos.startY and y <= pos.endY then
            return true, button
        end
    end
    return false, nil
end

return Monitor
