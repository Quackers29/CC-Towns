local Monitor = require("Monitor")
local Manager = require("Manager")
local CSV2D = require("CSV2D")
local Utility = require("Utility")
local buttonConfig = require("ButtonConfig")
local currentPage = "main" -- Default page to start
local x,y,z = gps.locate()
local town = "Towns\\Town_X"..x.."Y"..y.."Z"..z.."\\"
local resFile = town.."RES_X"..x.."Y"..y.."Z"..z..".json"
local upgradesFile = town.."UP_X"..x.."Y"..y.."Z"..z..".json"
local biomeFile = town.."BIO_X"..x.."Y"..y.."Z"..z..".txt"
local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".json"
local productionFile = town.."PRO_X"..x.."Y"..y.."Z"..z..".json"
local defaultSettingsFile = "Defaults\\defaultSettings.json"
local upgradesSource = "Defaults\\upgrades.json"
local productionSource = "Defaults\\production.json"
local covertFile = "Defaults\\convert.json"
local biomes = "Defaults\\biomes.txt"
local townNames = "Defaults\\townNames.txt"
local mainflag = true
local secondflag = true
local wait = 1
local productionWait = 10
local refreshflag = true
local displayItem = nil

local minWidth = 8
local minHeight = 2

local scheduledActions = {} -- A table to keep track of scheduled actions

-- Initialize checks / file system

if not fs.exists(SettingsFile) then
    Utility.copyFile(defaultSettingsFile,SettingsFile)
end

local Settings = Utility.readJsonFile(SettingsFile)

if Settings.general.biome == nil then
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
    Settings.general.biome = currentBiome or nil
    Settings.general.biomeDist = dist or nil
end

if Settings.town.name == nil then
    local townnameslist = Manager.readCSV(townNames)
    local randomIndex = math.random(1, #townnameslist)
    print(randomIndex)
    local townName = townnameslist[randomIndex].id
    Settings.town.name = townName
    print(townName)
end

Utility.writeJsonFile(SettingsFile,Settings)

if not fs.exists(upgradesFile) then
    local upgradeTable = Utility.readJsonFile(upgradesSource)
    local newTable = {}
    local test = Settings.upgrades.possible
    local autoCompleted = Settings.upgrades.base
    for i,v in ipairs(test) do
        local temp = upgradeTable[v]
        if temp then
            for x,y in ipairs(autoCompleted) do
                if y == v then
                    temp.toggle = true                   
                end
            end
            newTable[v] = temp
        end
    end
    Utility.writeJsonFile(upgradesFile,newTable)
end

if not fs.exists(productionFile) then
    local productionTable = Utility.readJsonFile(productionSource)
    Utility.writeJsonFile(productionFile,productionTable)
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
        local prevtable = Utility.readJsonFile(resFile)
        local displayTable = {}
        if prevtable then
            for i,v in pairs(prevtable) do
                for e,r in pairs(v) do
                    if r.count > 0 then
                        table.insert(displayTable,r)
                    end
                end
            end
            Monitor.drawList(2, endY, displayTable, pageButtons["list"], 1)
        end
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
    elseif currentPage == "upgrades" then
        displayItem = nil
        Monitor.write("Upgrades!", 1, 1)
        local displayTable = Utility.readJsonFile(upgradesFile)
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
        Monitor.drawKeyList(2, endY, displayTable, pageButtons["list"], 1)
    elseif currentPage == "production" then
        displayItem = nil
        Monitor.write("Production!", 1, 1)
        local displayTable = Utility.readJsonFile(productionFile)
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
        Monitor.drawKeyList(2, endY, displayTable, pageButtons["list"], 1)
    elseif currentPage == "display" then
        local canUp = true
        local prevtable = Utility.readJsonFile(resFile)
        local displayTable = Utility.readJsonFile(upgradesFile)
        Monitor.write("Upgrade: "..(displayItem.key or ""), 1, 1)
        Monitor.write("duration: "..(displayItem.duration or ""), 10, 2)
        Monitor.write("Cost: ", 10, 3)
        Monitor.write("Prerequisites: ", 10, ((endY-2)/2)+3)
        local index = 1
        local costTable = {}
        local PreRecTable = {}
        if type(displayItem.requires) ~= "table" then
            displayItem.requires ={displayItem.requires}
        end

        if displayItem.requires then
            for i,v in ipairs(displayItem.requires) do --
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
        for i,v in pairs(displayItem.cost) do
            local currentUp = true
            local c = Utility.convertItem(i)
            local d = 0
            if prevtable then
                for i,v in pairs(prevtable) do
                    for e,r in ipairs(v) do
                        if r.string == c then
                            d = r.count or 0
                        end
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
            else
                currentUp = false
                canUp = false
            end
            --Monitor.write(i.." = "..v.."        ", 1, 4 + index)
            --Monitor.write((d or "0"), 20, 4 + index)
            index = index + 1
            costTable[i] = costTable[i] or {}
            costTable[i]["key"] = i
            costTable[i]["extra"] = " = "..v.." : "..d
            costTable[i]["toggle"] = currentUp
            costTable[i]["string"] = c
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
        Monitor.write("Welcome to "..Settings.town.name.."!  @"..Settings.general.biome, 1, 1, colors.white)
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
    Manager.inputItems(resFile)
    Manager.checkItems(resFile)
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
    local prevtable = Utility.readJsonFile(resFile)
    for i,v in pairs(button.item.cost) do
        local c = Utility.convertItem(i)
        for x,y in pairs(prevtable) do
            for a,b in ipairs(y) do
                if b.string == c then
                    prevtable[x][a]["count"] = prevtable[x][a]["count"] - v
                end
            end
        end
    end
    Utility.writeJsonFile(resFile, prevtable)
    drawButtonsForCurrentPage()
end

function handleItem(button)
    local prevtable = Utility.readJsonFile(resFile)
    local selectedItem = button.item
    local itemstring = selectedItem.string
    local selectedToggle = selectedItem.toggle
    if selectedToggle == false then
        selectedToggle = true
    else
        selectedToggle = false
    end
    Utility.ModifyMcItemInTable(itemstring, prevtable, selectedToggle)
    Utility.writeJsonFile(resFile,prevtable)
    drawButtonsForCurrentPage()
end

function handleCSVItem(button)
    if button then
        if button.enabled then
            --adjustItems(button)
            local displayTable = Utility.readJsonFile(upgradesFile)
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
            Utility.writeJsonFile(upgradesFile,displayTable)
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
    scheduleAction(x.item.duration, function() handleCSVItem(y) end)
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

function productionCheck()
    local productionTable = Utility.readJsonFile(productionFile)
    local resTable = Utility.readJsonFile(resFile)
    local upgradesTable = Utility.readJsonFile(upgradesFile)
    local updateRes = false
    if productionTable and upgradesTable and resTable then
        for i,v in pairs(productionTable) do
            local gotRequires = true
            for l,m in ipairs(v.requires) do
                print(l,m)
                if upgradesTable[m] then
                    local checkUp = upgradesTable[m].toggle or nil
                    if checkUp == nil or checkUp == false then
                        gotRequires = false
                    end
                else
                    gotRequires = false
                end
            end
            if v.toggle and v.available and gotRequires then
                local currentItemLong = Utility.convertItem(i) -- short, long
                if currentItemLong then
                    local currentItemKey = nil
                    if resTable then
                        for c,b in ipairs(resTable) do
                            if b.id == currentItemLong then
                                currentItemKey = c
                            end
                        end
                    end
                    if currentItemKey then
                        if resTable[currentItemKey].count < v.max_storage - v.output and v.timer >= 0 then
                            if v.timer < 1 then
                                updateRes = true
                                resTable[currentItemKey].count = resTable[currentItemKey].count + v.output
                                local takeRes = true
                                for x,y in pairs(v.cost) do
                                    local currentItemLong = Utility.convertItem(i)
                                    local currentItemKey = nil
                                    for c,b in ipairs(resTable) do
                                        if b.id == currentItemLong then
                                            currentItemKey = c
                                        end
                                    end
                                    if not currentItemKey then
                                        takeRes = false
                                        v.toggle = false
                                    end
                                end
                                if takeRes then
                                    for x,y in pairs(v.cost) do
                                        local currentItemLong = Utility.convertItem(i)
                                        local currentItemKey = nil
                                        for c,b in ipairs(resTable) do
                                            if b.id == currentItemLong then
                                                currentItemKey = c
                                            end
                                        end
                                        if currentItemKey then
                                            if resTable[currentItemKey].count > y then
                                                resTable[currentItemKey].count = resTable[currentItemKey].count - y
                                            else
                                                v.toggle = false
                                            end
                                        else
                                            v.toggle = false
                                        end
                                    end
                                end
                                v.timer = v.duration
                            else
                                v.timer = v.timer - productionWait -- check if res met to decrease timer
                            end
                        end
                    end
                end
            end
        end
    end
    if updateRes then
        Utility.writeJsonFile(resFile,resTable)
    end
    Utility.writeJsonFile(productionFile,productionTable)
end

function productionTimer()
    while mainflag do
            productionCheck()
        os.sleep(productionWait)
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
parallel.waitForAll(main, second, handleScheduledActions, productionTimer)

-- Code here continues after both loops have exited
print("Both loops have exited.")
