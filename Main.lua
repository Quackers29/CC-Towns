
local Monitor = require("Monitor")
local Manager = require("Manager")
local CSV2D = require("CSV2D")
local buttonConfig = require("ButtonConfig") -- Load the external button configuration
local currentPage = "upgrades" -- Default page to start
local x,y,z = gps.locate()
local filename = "RES_X"..x.."Y"..y.."Z"..z..".txt"
local upgradesFile = "upgrades.txt"
local covertFile = "convert.txt"
local mainflag = true
local secondflag = true
local wait = 1
local refreshflag = true
local displayItem = nil

local minWidth = 8
local minHeight = 2

function drawButtonsForCurrentPage()
    Monitor.clear()
    Monitor.ClearButtons()
    
    
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

    -- Call the function to draw the grid with buttons
    if currentPage == "resources" then
        Monitor.write("Resources!", 1, 1)
        local prevtable = Manager.readCSV(filename)
        local displayTable = {}
        for i,v in pairs(prevtable) do
            if v.count > 0 then
                table.insert(displayTable,v)
            end
        end
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
        Monitor.drawList(2, endY, displayTable, pageButtons["list"], 1)
    elseif currentPage == "upgrades" then
        displayItem = nil
        Monitor.write("Upgrades!", 1, 1)
        local displayTable = CSV2D.readCSV2D(upgradesFile)
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
        Monitor.drawKeyList(2, endY, displayTable, pageButtons["list"], 1)
    elseif currentPage == "display" then
        local canUp = true
        local prevtable = Manager.readCSV(filename)
        Monitor.write("Upgrade: "..(displayItem.key or ""), 1, 1)
        Monitor.write("Duration: "..(displayItem.Duration or ""), 1, 3)
        Monitor.write("Cost: ", 1, 4)
        local index = 1
        for i,v in pairs(displayItem.Cost) do
            local convertTable = CSV2D.readCSV2D(covertFile)
            local c = nil
            local d = nil
            for a,b in pairs(convertTable) do
                print(i,v, a,b.convert)
                if i == a then
                    c = b.convert
                end
            end
            for i,v in ipairs(prevtable) do
                if v.id == c then
                    d = v.count
                end
            end
            if d < v then
                canUp = false
            end
            Monitor.write(i.." = "..v.."        ", 1, 4 + index)
            Monitor.write((d or "0"), 20, 4 + index)
            index = index + 1
        end
        for i,v in ipairs(pageButtons["button"]) do
            if v.id == "Up" then
                v.enabled = canUp
                v.item = displayItem
            end
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
    else
        Monitor.write("Welcome to Town!", 1, 1)
        Monitor.drawFlexibleGrid(startX, startY, endX, endY, minWidth, minHeight, pageButtons["push"])
    end
end

-- Initialize the monitor and set the default page
Monitor.init()
drawButtonsForCurrentPage()

-- An example function (e.g., inside a button action) to transition to the "settings" page:

function goToPage(x)
    currentPage = x
    Monitor.OffsetButton(0)
    drawButtonsForCurrentPage()
end

function goToDisplayPage(x)
    displayItem = x.item
    currentPage = "display"
    drawButtonsForCurrentPage()
end


function OffsetButton(x)
    Monitor.OffsetButton(x)
    drawButtonsForCurrentPage()
end

function RefreshButton()
    Manager.inputItems(filename)
    Manager.checkItems(filename)
    if currentPage == "resources" or currentPage == "display" then
        drawButtonsForCurrentPage()     
    end
end

function RefreshFlag()
    if refreshflag then
        refreshflag = false
    else
        refreshflag = true
    end
end

function adjustItems(button)
    local prevtable = Manager.readCSV(filename)
    for i,v in pairs(button.item.Cost) do
        local convertTable = CSV2D.readCSV2D(covertFile)
        local c = nil
        local d = nil
        for a,b in pairs(convertTable) do
            print(i,v, a,b.convert)
            if i == a then
                c = b.convert
            end
        end
        for x,y in ipairs(prevtable) do
            if y.id == c then
                prevtable[x]["count"] = prevtable[x]["count"] - v
            end
        end
    end
    Manager.writeCSV(filename, prevtable)
    drawButtonsForCurrentPage()
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

function handleCSVItem(button)
    if button.enabled then
        adjustItems(button)
        local displayTable = CSV2D.readCSV2D(upgradesFile)
        local selectedToggle = button.item.toggle
        --print(selectedToggle)
        if selectedToggle == "false" or selectedToggle == "FALSE" or selectedToggle == false then
            selectedToggle = true
        else
            selectedToggle = false
        end
        --print(selectedToggle)
        displayTable[button.item.key]["toggle"] = selectedToggle
        --print("new: "..tostring(displayTable[button.item.key]["toggle"]))
        CSV2D.writeCSV2D(displayTable,upgradesFile)
    end
    drawButtonsForCurrentPage()
end

-- Event loop remains the same
function main()
    while mainflag do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local clicked, button = Monitor.isInsideButton(x, y)
        --print(clicked, button.id)
        if clicked and (button.page == currentPage or "all") then --and button.enabled
            if button.action then
                button.action(button)
            end
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
