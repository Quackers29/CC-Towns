local Monitor = require("Monitor")
local Manager = require("Manager")
local buttonConfig = require("ButtonConfig") -- Load the external button configuration
local currentPage = "main" -- Default page to start
local x,y,z = gps.locate()
local filename = "RES_X"..x.."Y"..y.."Z"..z..".txt"
local mainflag = true
local secondflag = true
local wait = 1
local refreshflag = true

local minWidth = 8
local minHeight = 2

function drawButtonsForCurrentPage()
    Monitor.clear()
    Monitor.ClearButtons()
    Monitor.write("Welcome to Town!", 1, 1)
    
    -- Filter the buttons for the current page
    local pageButtons = {}
    for _, config in ipairs(buttonConfig) do
        if config.page == currentPage then
            pageButtons[config.type] = pageButtons[config.type] or {}
            table.insert(pageButtons[config.type], config)
        end
    end

    -- Get monitor size
    local width, height = Monitor.getSize()
    -- Define your grid area (you can adjust these values as per your needs)
    local startX = 1
    local startY = 3
    local endX = width - 1
    local endY = height -- -1

    local prevtable = Manager.readCSV(filename)

    local displayTable = {}
    for i,v in pairs(prevtable) do
        if v.count > 0 then
            table.insert(displayTable,v)
        end
    end

    -- Call the function to draw the grid with buttons
    if currentPage == "resources" then
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
        Monitor.drawList(2, endY, displayTable, pageButtons["list"], 1)
    else
        Monitor.drawFlexibleGrid(startX, startY, endX, endY, minWidth, minHeight, pageButtons["push"])
    end
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

function goToResourcesPage()
    currentPage = "resources"
    Monitor.OffsetButton(0)
    drawButtonsForCurrentPage()
end

function goToMainPage()
    currentPage = "main"
    Monitor.OffsetButton(0)
    drawButtonsForCurrentPage()
end

function OffsetButton(x)
    Monitor.OffsetButton(x)
    drawButtonsForCurrentPage()
end

function RefreshButton()
    Manager.inputItems(filename)
    Manager.checkItems(filename)
    drawButtonsForCurrentPage()
end

function RefreshFlag()
    if refreshflag then
        refreshflag = false
    else
        refreshflag = true
    end
end

function handleItem(button)
    local prevtable = Manager.readCSV(filename)
    local selectedItem = button.item.id
    local selectedToggle = button.item.toggle
    if selectedToggle == false then
        selectedToggle = true
    else
        selectedToggle = false
    end
    local xtable = {}
    local ytable = {}
    ytable["id"] = selectedItem
    ytable["toggle"]  = selectedToggle
    table.insert(xtable,ytable)
    Manager.writeCSV(filename, Manager.mergetable(prevtable,xtable))
    drawButtonsForCurrentPage()
end

-- Event loop remains the same
function main()
    while mainflag do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local clicked, button = Monitor.isInsideButton(x, y)
        --print(clicked, button.id)
        if clicked and (button.page == currentPage or "all") then --and button.enabled
            button.action(button)
        end
    end
end

function second()
    while secondflag do
        if refreshflag then
            RefreshButton()
        end
        os.sleep(wait)
    end
end

-- Start the loops
parallel.waitForAll(main, second)

-- Code here continues after both loops have exited
print("Both loops have exited.")
