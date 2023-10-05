local Monitor = require("Monitor")
local buttonConfig = require("ButtonConfig") -- Load the external button configuration
local currentPage = "main" -- Default page to start

local minWidth = 8
local minHeight = 2

function drawButtonsForCurrentPage()
    Monitor.clear()
    Monitor.write("Welcome to Town!", 1, 1)
    
    -- Filter the buttons for the current page
    local pageButtons = {}
    for _, config in ipairs(buttonConfig) do
        if config.page == currentPage then
            table.insert(pageButtons, config)
        end
    end

    -- Get monitor size
    local width, height = Monitor.getSize()
    -- Define your grid area (you can adjust these values as per your needs)
    local startX = 1
    local startY = 3
    local endX = width - 1
    local endY = height - 1


    -- Call the function to draw the grid with buttons
    Monitor.drawFlexibleGrid(startX, startY, endX, endY, minWidth, minHeight, pageButtons)
end

-- Initialize the monitor and set the default page
Monitor.init()
drawButtonsForCurrentPage()

-- An example function (e.g., inside a button action) to transition to the "settings" page:
function goToSettingsPage()
    currentPage = "settings"
    Monitor.OffsetButton(0)
    drawButtonsForCurrentPage()
end

function goToMainPage()
    currentPage = "main"
    Monitor.OffsetButton(0)
    drawButtonsForCurrentPage()
end

function OffsetButton(x)
    print("Off: ",x)
    Monitor.OffsetButton(x)
    drawButtonsForCurrentPage()
end

-- Event loop remains the same
while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    local clicked, button = Monitor.isInsideButton(x, y)
    print(clicked)
    if clicked and button.enabled and (button.page == currentPage or "all") then
        print(button)
        button.action()
    end
end