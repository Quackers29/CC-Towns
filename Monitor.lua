-- Monitor.lua

local Monitor = {}
local monitor
local buttons = {} -- Table to store drawn buttons

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
        table.insert(buttons, {
            name = identifier,
            x = x,
            y = y,
            width = width,
            height = height
        })
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
    table.insert(buttons, {
        name = identifier,
        x = position == "right" and x + #text or x,
        y = y,
        width = buttonWidth,
        height = 1 -- Since it's a single line button
    })
end

function Monitor.isInsideButton(x, y)
    for _, button in pairs(buttons) do
        if x >= button.x and x <= button.x + button.width + 1 and y >= button.y and y <= button.y + button.height + 1 then
            return true, button.name
        end
    end
    return false, nil
end

-- ... Additional functions such as scroll, resize, etc. can be added later

return Monitor
