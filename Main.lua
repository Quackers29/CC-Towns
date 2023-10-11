local Monitor = require("Monitor")
local Manager = require("Manager")
local CSV2D = require("CSV2D")
local buttonConfig = require("ButtonConfig")
local currentPage = "main" -- Default page to start
local x,y,z = gps.locate()
local town = "Towns\\Town_X"..x.."Y"..y.."Z"..z.."\\"
local filename = town.."RES_X"..x.."Y"..y.."Z"..z..".txt"
local upgradesFile = town.."UP_X"..x.."Y"..y.."Z"..z..".txt"
local biomeFile = town.."BIO_X"..x.."Y"..y.."Z"..z..".txt"
local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".txt"
local upgradesSource = "upgrades.txt"
local covertFile = "convert.txt"
local biomes = "biomes.txt"
local townNames = "townNames.txt"
local defaultSettingsFile = "defaultSettings.txt"
local mainflag = true
local secondflag = true
local wait = 1
local refreshflag = true
local displayItem = nil

local minWidth = 8
local minHeight = 2

local scheduledActions = {} -- A table to keep track of scheduled actions

-- Initialize checks / file system

function copyFile(sourcePath, destinationPath)
    if fs.exists(sourcePath) and not fs.isDir(sourcePath) then
        if fs.copy(sourcePath, destinationPath) then
            return true
        else
            print("Failed to copy the file.")
            return false
        end
    else
        print("Source file does not exist or is a directory.")
        return false
    end
end


if not fs.exists(SettingsFile) then
    copyFile(defaultSettingsFile,SettingsFile)
end

local Settings = CSV2D.readCSV2D(SettingsFile)

if Settings.general.item.biome == "nil" then
    local currentBiome = nil
    local dist = 9999
    if not fs.exists(biomeFile) then
        local biomeslist = Manager.readCSV(biomes)
        local newList = {}
        for i,v in pairs(biomeslist) do
            print(i,v)
            print(v.id)
            local boolean, tableWithString, distance = commands.locate.biome(v.id)
            if boolean or string.match(tableWithString[1], "(0 blocks away)") then
                if distance < dist then
                    dist = distance
                    currentBiome = v.id
                end
            else
                distance = nil
            end
            newList[v.id] = newList[v.id] or {}
            newList[v.id].distance = distance
            print(distance)
        end
        CSV2D.writeCSV2D(newList,biomeFile)
        print("Out: ",currentBiome, dist)
    end
    currentBiome = currentBiome:match("_(.*)$") or currentBiome
    Settings.general.item.biome = currentBiome or nil
    Settings.general.item.biomeDist = dist or nil
end

if Settings.town.item.name == "nil" then
    local townnameslist = Manager.readCSV(townNames)
    local randomIndex = math.random(1, #townnameslist)
    print(randomIndex)
    local townName = townnameslist[randomIndex].id
    Settings.town.item.name = townName
    print(townName)
end

function saveTableToJsonFile(filePath, luaTable)
    local serializedData = textutils.serializeJSON(luaTable)
    local file = fs.open(filePath, "w")

    if file then
        file.write(serializedData)
        file.close()
        return true  -- Successfully saved to file
    else
        return false  -- Failed to open file
    end
end

saveTableToJsonFile("testJSON.json",Settings)

CSV2D.writeCSV2D(Settings,SettingsFile)
if not fs.exists(upgradesFile) then
    print("no")
    local upgradeTable = CSV2D.readCSV2D(upgradesSource)
    local newTable = {}
    print("2")
    print("no")
    print(Settings.upgrades.item.possible)
    local test = textutils.unserialize(Settings.upgrades.item.possible)
    for i,v in ipairs(test) do
        print("3")
        local temp = upgradeTable[v]
        print(i,v,temp)
        if temp then
            print("4")
            newTable[v] = temp
        end
    end
    CSV2D.writeCSV2D(newTable,upgradesFile)
end

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
        local displayTable = CSV2D.readCSV2D(upgradesFile)
        Monitor.write("Upgrade: "..(displayItem.key or ""), 1, 1)
        Monitor.write("Duration: "..(displayItem.Duration or ""), 10, 2)
        Monitor.write("Cost: ", 10, 3)
        Monitor.write("Prerequisites: ", 10, ((endY-2)/2)+3)
        local index = 1
        local costTable = {}
        local PreRecTable = {}
        if type(displayItem.Prerequisites) ~= "table" then
            displayItem.Prerequisites ={displayItem.Prerequisites}
        end

        if displayItem.Prerequisites then
            for i,v in ipairs(displayItem.Prerequisites) do --
                --print(v)
                local currentUp = false
                for x,y in pairs(displayTable) do
                    if x == v then
                        if y.toggle then
                            currentUp = true
                        end
                    end
                end
                if not currentUp then
                    canUp = false
                end
                PreRecTable[v] = PreRecTable[v] or {}
                PreRecTable[v]["key"] = v
                PreRecTable[v]["extra"] = ""
                PreRecTable[v]["toggle"] = currentUp
            end
            Monitor.drawKeyList(((endY-2)/2)+4, endY, PreRecTable, pageButtons["list"], 1, 1) 
        end

        local convertTable = CSV2D.readCSV2D(covertFile)
        for i,v in pairs(displayItem.Cost) do
            local currentUp = true
            local c = nil
            local d = nil
            for a,b in pairs(convertTable) do
                --print(i,v, a,b.convert)
                if i == a then
                    c = b.convert
                end
            end
            for i,v in ipairs(prevtable) do
                if v.id == c then
                    d = v.count
                end
            end
            if d ~= nil then
                if d < v then
                    canUp = false
                    currentUp = false
                end
            else
                canUp = false
                currentUp = false
            end
            --Monitor.write(i.." = "..v.."        ", 1, 4 + index)
            --Monitor.write((d or "0"), 20, 4 + index)
            index = index + 1
            costTable[i] = costTable[i] or {}
            costTable[i]["key"] = i
            costTable[i]["extra"] = " = "..v.." : "..d
            costTable[i]["toggle"] = currentUp
        end
        Monitor.drawKeyList(4, ((endY-2)/2)+2, costTable, pageButtons["list"], 1, 0)


        for i,v in ipairs(pageButtons["button"]) do
            if v.id == "Up" then
                v.enabled = canUp
                v.item = displayItem
            end
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
    else
        Monitor.write("Welcome to "..Settings.town.item.name.."!  @"..Settings.general.item.biome, 1, 1, colors.white)
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


function OffsetButton(x,y)
    --print(x,y)
    Monitor.OffsetButton(x,y)
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
            --print(i,v, a,b.convert)
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
    if button then
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
end

-- Function to schedule an action
function scheduleAction(delayInSeconds, action)
    local timerID = os.startTimer(delayInSeconds)
    scheduledActions[timerID] = action
end

function UpgradeSchedule(x)
    local y = x
    scheduleAction(x.item.Duration, function() handleCSVItem(y) end)
end

-- Event loop remains the same
function main()
    while mainflag do
        local event, side, x, y = os.pullEvent("monitor_touch")
        local clicked, button = Monitor.isInsideButton(x, y)
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

-- Function to handle scheduled actions
function handleScheduledActions()
    while mainflag do
        local event, timerID = os.pullEvent("timer")
        if scheduledActions[timerID] then
            scheduledActions[timerID]()  -- Execute the scheduled action
            scheduledActions[timerID] = nil  -- Remove the action from the table
        end
    end
end

-- Start a background thread to handle scheduled actions
--parallel.waitForAny(handleScheduledActions, function()
    -- This can be used for other tasks or user interaction
    --print("Main program running...")
--end)

-- Start the loops
parallel.waitForAll(main, second, handleScheduledActions)

-- Code here continues after both loops have exited
print("Both loops have exited.")
