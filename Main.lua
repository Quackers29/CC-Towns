local Monitor = require("Monitor")
local Manager = require("Manager")
local Utility = require("Utility")
local buttonConfig = require("ButtonConfig")
local currentPage = "main" -- Default page to start
local x,y,z = gps.locate()
local townFolder = "Town_X"..x.."Y"..y.."Z"..z
local town = "Towns\\"..townFolder.."\\"
local resFile = town.."RES_X"..x.."Y"..y.."Z"..z..".json"
local upgradesFile = town.."UP_X"..x.."Y"..y.."Z"..z..".json"
local biomeFile = town.."BIO_X"..x.."Y"..y.."Z"..z..".json"
local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".json"
local productionFile = town.."PRO_X"..x.."Y"..y.."Z"..z..".json"
local tradeFile = town.."TRD_X"..x.."Y"..y.."Z"..z..".json"
local defaultSettingsFile = "Defaults\\settings.json"
local upgradesSource = "Defaults\\upgrades.json"
local productionSource = "Defaults\\production.json"
local tradeSource = "Defaults\\trades.json"
local covertFile = "Defaults\\convert.json"
local biomes = "Defaults\\biomes.txt"
local townNames = "Defaults\\townNames.txt"
local mainflag = true
local secondflag = true
local wait = 5 --IN/OUT wait timer
local productionWait = 10
local refreshflag = true
local displayItem = nil
local INx,INy,INz = nil,nil,nil
local OUTx,OUTy,OUTz = nil,nil,nil
local ChestRange = 5 -- blocks away from the Town PC
local LastX,LastY = 1,1 -- use for map coordinates
local adminFile = "AdminSettings.json"
local currentZoom = 1 -- 1 for 1
-- PushButtons
local minWidth = 8
local minHeight = 2

local PINx,PINy,PINz = 11,-59,-37 --population input coords
local POUTx,POUTy,POUTz = 11,-59,-47 --population output coords

local scheduledActions = {} -- A table to keep track of scheduled actions


function CalcDist(x1, z1, x2, z2)
    return math.sqrt((x2 - x1)^2 + (z2 - z1)^2)
end

function InRange(value, origin, range)
    return math.max(origin - range, math.min(value, origin + range))
end

function IsInRange(value, origin, range)
    return value >= (origin - range) and value <= (origin + range)
end

function IsInRange2DAngular(X, Z, originX, originZ, range)
    local distance = math.sqrt((X - originX)^2 + (Z - originZ)^2)
    return distance <= range
end

function CoerceInRange2DAngular(X, Z, originX, originZ, range)
    local dx = X - originX
    local dz = Z - originZ
    local distance = math.sqrt(dx^2 + dz^2)
    
    if distance <= range then
        return X, Z  -- Point is within range, return it as is
    end

    -- Calculate scaling factor
    local scale = range / distance

    -- Coerce point to be on the border of the circle with radius `range`
    local coercedX = originX + dx * scale
    local coercedZ = originZ + dz * scale
    
    return coercedX, coercedZ, distance
end

-- Initialize Checks if it exists or should exist
local TownFlag = false
local NearbyTowns = {}
for i,v in ipairs(fs.list("Towns")) do
    local ax, ay, az = string.match(v, "X(%-?%d+)Y(%-?%d+)Z(%-?%d+)")
    table.insert(NearbyTowns,{x = ax,y = ay,z = az})
    if v == townFolder then
        print("Town already exist")
        TownFlag = true
    end
end

local AdminSettings = Utility.readJsonFile(adminFile)

if AdminSettings and AdminSettings.Town.MinDistance then
    local deleteTown = false
    if not TownFlag then
        print("Town does not already exist")
        for i,v in ipairs(fs.list("Towns")) do
            local ax, ay, az = string.match(v, "X(%-?%d+)Y(%-?%d+)Z(%-?%d+)")
            if IsInRange2DAngular(ax, az, x, z, AdminSettings.Town.MinDistance) then
                print("NewTown is within another Town, deleting Computer")
                os.sleep(10)
                commands.fill(x,y,z,x,y,z,"cobblestone")
                error("Program terminated, Computer deleted")
                break
            end
        end
    end
end


-- Initialize checks / file system

if not fs.exists(SettingsFile) then
    Utility.copyFile(defaultSettingsFile,SettingsFile)
end

if not fs.exists(tradeFile) then
    Utility.copyFile(tradeSource,tradeFile)
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
            local listItem = {}
            local boolean, tableWithString, distance = commands.locate.biome(v.id)
            local mod, key = string.match(tableWithString[1], "%((.-):(.-)%)")
            local x, y, z = string.match(tableWithString[1], "%[([^,]+),([^,]+),([^%]]+)%]")
            if boolean or string.match(tableWithString[1], "(0 blocks away)") then
                if distance < dist then
                    dist = distance
                    currentBiome = v.id
                end
            else
                distance = nil
            end
            listItem = {mod = mod,key = key,x = tonumber(x),y = tonumber(y),z = tonumber(z),distance = distance}
            table.insert(newList,listItem)
            print(distance)
        end
        Utility.writeJsonFile(biomeFile,newList)
        print("Out: ",currentBiome, dist)
    end
    currentBiome = currentBiome:match("_(.*)$") or currentBiome
    Settings.general.biome = currentBiome or nil
    Settings.general.biomeDist = dist or nil
end

if Settings and Settings.town.name == nil then
    local townnameslist = Manager.readCSV(townNames)
    local randomIndex = math.random(1, #townnameslist)
    print(randomIndex)
    local townName = townnameslist[randomIndex].id
    Settings.town.name = townName
    Settings.town.born = os.date("%Y-%m-%d %H:%M:%S", os.epoch("utc")/1000)
    Settings.town.timestamp = os.epoch("utc")
    print(townName)
    print("Created (utc): "..Settings.town.born)
end

if Settings.Input and math.abs(Settings.Input.x - x) <= ChestRange and math.abs(Settings.Input.y - y) <= ChestRange then
    INx,INy,INz = Settings.Input.x, Settings.Input.y, Settings.Input.z
else
    Settings.Input = {}
    Settings.Input.x, Settings.Input.y, Settings.Input.z = x+1,y,z
    INx,INy,INz = Settings.Input.x, Settings.Input.y, Settings.Input.z
end

if Settings.Output and math.abs(Settings.Output.x - x) <= ChestRange and math.abs(Settings.Output.y - y) <= ChestRange then
    OUTx,OUTy,OUTz = Settings.Output.x, Settings.Output.y, Settings.Output.z
else
    Settings.Output = {}
    Settings.Output.x, Settings.Output.y, Settings.Output.z = x+1,y+2,z
    OUTx,OUTy,OUTz = Settings.Output.x, Settings.Output.y, Settings.Output.z
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
        local resTable = Utility.readJsonFile(resFile)
        local displayTable = {}
        if resTable then
            for i,v in pairs(resTable) do
                if v.count > 0 then
                    v.string = i
                    table.insert(displayTable,v)
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
        
    elseif currentPage == "settings_InputChest" then
        Monitor.write("Settings - Input Chest!", 1, 1, colors.white)
        Monitor.write("X: "..INx.." Y: "..INy.." Z: "..INz,1, 5, colors.white)
        commands.particle("block_marker", "chest", INx, INy, INz, 0, 0, 0, 0.5, 10, "normal")
        commands.particle("end_rod", INx, INy, INz, 0, 0, 0, 0.03, 100, "normal")
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end

    elseif currentPage == "settings_OutputChest" then
        Monitor.write("Settings - Output Chest!", 1, 1, colors.white)
        Monitor.write("X: "..OUTx.." Y: "..OUTy.." Z: "..OUTz,1, 5, colors.white)
        commands.particle("block_marker", "chest", OUTx, OUTy, OUTz, 0, 0, 0, 0.5, 10, "normal")
        commands.particle("end_rod", OUTx, OUTy, OUTz, 0, 0, 0, 0.03, 100, "normal")
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end

    elseif currentPage == "Map" then
        Monitor.write(Settings.town.name.." - Map (Zoom:"..currentZoom..")", 1, 1, colors.white)
        local currentTown = {x = x, z = z}
        local topLeftX, topLeftY = 1, 2  -- x,y
        local mapWidth, mapHeight = width - topLeftX, height - topLeftY
        local zoom = 1
        for i,v in ipairs(pageButtons["button"]) do
            Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
        end
        Monitor.displayMap(NearbyTowns, currentTown, topLeftX, topLeftY, mapWidth, mapHeight, currentZoom)
    elseif currentPage == "display_upgrade" then
        local canUp = true
        local resTable = Utility.readJsonFile(resFile)
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
            if resTable then
                if resTable[c] ~= nil then
                     d = resTable[c].count or 0
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
    elseif displayItem and currentPage == "display_production" then
        local canUp = true
        local resTable = Utility.readJsonFile(resFile)
        local displayTable = Utility.readJsonFile(upgradesFile)
        local productionTable = Utility.readJsonFile(productionFile)
        Monitor.write("Produce: "..((displayItem.key.." x"..displayItem.output) or ""), 1, 1)
        Monitor.write("duration: "..(displayItem.duration or "").."("..displayItem.timer..")", 10, 2)
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
            if resTable then
                if resTable[c] ~= nil then
                    d = resTable[c].count or 0
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
        -- Add back to main button if no buttons assigned to page
        if pageButtons == {} then
            Monitor.write("Welcome to "..Settings.town.name.."! - "..currentPage, 1, 1, colors.white)
            Monitor.drawButton(Monitor.OffsetCheck(-1, endX),Monitor.OffsetCheck(0, endY),{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("main") end,enabled = true, type = "button",page = "all"})
        else
            Monitor.write("Welcome to "..Settings.town.name.."! - "..currentPage, 1, 1, colors.white)
            Monitor.drawFlexibleGrid(startX, startY, endX, endY, minWidth, minHeight, pageButtons["push"])
        end

    end
end

-- Initialize the monitor and set the default page
Monitor.init()
drawButtonsForCurrentPage()



function Offer()
    --This Updates a Towns current Offers list 
    --1. Check if there is space for another offer in the list
    --2. Checks what could be a new offer and adds its
    local trades = Utility.readJsonFile(tradeFile)
    local settings = Utility.readJsonFile(SettingsFile)
    local resTable = Utility.readJsonFile(resFile)

    if trades and settings and resTable then
        -- check if there is room for an offer, only add one
        if Utility.getArraySize(trades.offers.buying) < trades.offers.limit then
            -- make a list of all current buying offers
            for i,v in pairs(settings.resources.keepInstock) do
                local continue = true
                if trades.offers.buying[i] ~= nil then
                    continue = false
                end
                if continue then -- keepInstock item not in buy list, check resources
                    --local itemShort = string.match(i,":(.+)")
                    print("Searching: "..i)
                    local count = 0
                    if resTable[i] then
                        count = resTable[i].count
                        print("BuyCount: "..count.." < "..(v*settings.resources.restockThreshold))
                        if count < (v*settings.resources.restockThreshold) then
                            -- attempt add the buying
                            resTable[i].count = v - count
                            resTable[i].price = {
                                emerald = {
                                string = "minecraft:emerald",
                                attributes = "",
                                key = "emerald",
                                count = resTable[i].count
                                }
                                }
                            if not trades.offers.buying[i] then
                                trades.offers.buying[i] = {}
                            end
                            trades.offers.buying[i] = resTable[i]
                        end
                    end
                end
            end
        end
        if Utility.getArraySize(trades.offers.selling) < trades.offers.limit then
            -- make a list of all current selling offers
            for i,v in pairs(settings.resources.keepInstock) do
                local continue = true
                if trades.offers.selling[i] ~= nil then
                    continue = false
                end
                if continue then -- keepInstock item not in sell list, check resources
                    local count = 0
                    if resTable[i] then
                        count = resTable[i].count
                        print("SellCount: "..count.." > "..(v*settings.resources.excessThreshold))
                        if count > (v*settings.resources.excessThreshold) then
                            -- attempt add the selling
                            resTable[i].count = count-v
                            resTable[i].price = {
                                emerald = {
                                string = "minecraft:emerald",
                                attributes = "",
                                key = "emerald",
                                count = resTable[i].count
                                }
                                }
                            if not trades.offers.selling[i] then
                                trades.offers.selling[i] = {}
                            end
                            trades.offers.selling[i] = resTable[i]
                        end
                    end
                end
            end
        end
        Utility.writeJsonFile(tradeFile,trades)
    end
end


function goToPage(x)
    currentPage = x
    Monitor.OffsetButton(0)
    drawButtonsForCurrentPage()
end

function goToDisplayPage(x, todisplay)
    displayItem = x.item
    currentPage = todisplay
    drawButtonsForCurrentPage()
end

function OffsetButton(x,y)
    Monitor.OffsetButton(x,y)
    drawButtonsForCurrentPage()
end

function OffsetZoom(x)
    currentZoom = math.max((currentZoom + x),1)
    drawButtonsForCurrentPage()
end

function ChangeInputChest(ax,ay,az)
    Settings = Utility.readJsonFile(SettingsFile)
    INx = math.max(x - ChestRange, math.min(INx + ax, x + ChestRange))
    INy = math.max(y - ChestRange, math.min(INy + ay, y + ChestRange))
    INz = math.max(z - ChestRange, math.min(INz + az, z + ChestRange))
    Settings.Input.x,Settings.Input.y,Settings.Input.z = INx,INy,INz
    Utility.writeJsonFile(SettingsFile,Settings)
    drawButtonsForCurrentPage()
end

function ChangeOutputChest(ax,ay,az)
    Settings = Utility.readJsonFile(SettingsFile)
    OUTx = math.max(x - ChestRange, math.min(OUTx + ax, x + ChestRange))
    OUTy = math.max(y - ChestRange, math.min(OUTy + ay, y + ChestRange))
    OUTz = math.max(z - ChestRange, math.min(OUTz + az, z + ChestRange))
    Settings.Output.x,Settings.Output.y,Settings.Output.z = OUTx,OUTy,OUTz
    Utility.writeJsonFile(SettingsFile,Settings)
    drawButtonsForCurrentPage()
end

function OutputPOP()
    local timeX = os.clock()
    commands.summon("minecraft:villager",POUTx,POUTy,POUTz,"{CustomName:'{\"text\":\""..Settings.town.name.."\"}'}")
    commands.summon("minecraft:villager",POUTx,POUTy,POUTz,"{CustomName:'{\"text\":\"".."Clock"..timeX.."\"}'}")
end

function InputPOP()
    local test1 = "@e[type=minecraft:villager,x="..tostring(PINx)..",y="..tostring(PINy)..",z="..tostring(PINz)..",distance=..8,name=!Villager,limit=1]" --OR "..Settings.town.name.."
    local boolean,table,count = commands.kill(test1)
    local result = string.match(table[1], "Killed (.+)")
    print(result)
end

function RefreshButton()
    Manager.inputItems(resFile,INx,INy,INz)
    Manager.checkItems(resFile,OUTx,OUTy,OUTz)
    if currentPage == "resources" or currentPage == "display_upgrade" or currentPage == "display_production" then
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
    local resTable = Utility.readJsonFile(resFile)
    for i,v in pairs(button.item.cost) do
        local c = Utility.convertItem(i)
        if resTable and resTable[c] ~= nil then
            resTable[c]["count"] = resTable[c]["count"] - v
        end
    end
    Utility.writeJsonFile(resFile, resTable)
    drawButtonsForCurrentPage()
end

function handleItem(button)
    local resTable = Utility.readJsonFile(resFile)
    local selectedItem = button.item
    local itemstring = selectedItem.string
    local selectedToggle = selectedItem.toggle
    if selectedToggle == false then
        selectedToggle = true
    else
        selectedToggle = false
    end
    Utility.ModifyMcItemInTable(itemstring, resTable, selectedToggle)
    Utility.writeJsonFile(resFile,resTable)
    drawButtonsForCurrentPage()
end

function handleCSVItem(button)
    if button then
        if button.enabled then
            --adjustItems(button)
            local displayTable = Utility.readJsonFile(upgradesFile)
            local selectedToggle = button.item.toggle
            if selectedToggle == "false" or selectedToggle == "FALSE" or selectedToggle == false then
                selectedToggle = true
            else
                selectedToggle = false
            end
            displayTable[button.item.key]["toggle"] = selectedToggle
            Utility.writeJsonFile(upgradesFile,displayTable)
        end
        drawButtonsForCurrentPage()
    end
end

function handleProduction(button)
    if button then
        if button.enabled then
            --adjustItems(button)
            local displayTable = Utility.readJsonFile(productionFile)
            local selectedToggle = button.item.toggle
            if selectedToggle == "false" or selectedToggle == "FALSE" or selectedToggle == false then
                selectedToggle = true
            else
                selectedToggle = false
            end
            displayTable[button.item.key]["toggle"] = selectedToggle
            Utility.writeJsonFile(productionFile,displayTable)
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
        LastX, LastY = x,y
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
    local settings = Utility.readJsonFile(SettingsFile)
    local updateRes = false
    if productionTable and upgradesTable and resTable and settings then
        for i,v in pairs(productionTable) do
            local gotRequires = true
            for l,m in ipairs(v.requires) do
                --print(l,m)
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
                    local itemStop = false
                    if resTable[currentItemLong] ~= nil then
                        if resTable[currentItemLong].count < v.max_storage - v.output then
                        else
                            itemStop = true
                        end
                    end
                    if not itemStop then
                        if v.timer < productionWait then
                            local resourcesPull = {}
                            updateRes = true
                            table.insert(resourcesPull,{currentItemLong=currentItemLong,count = v.output})
                            local takeRes = true
                            local canUp = true
                            for x,y in pairs(v.cost) do
                                local currentItemLong = Utility.convertItem(x)
                                if resTable[currentItemLong] ~= nil then
                                    if resTable[currentItemLong].count >= y then
                                        table.insert(resourcesPull,{currentItemLong=currentItemLong,count = - y})
                                    else
                                        canUp = false
                                        v.toggle = false
                                    end
                                else
                                    canUp = false
                                    v.toggle = false
                                end
                            end
                            if canUp then
                                for i,v in ipairs(resourcesPull) do
                                    Utility.AddMcItemToTable(v.currentItemLong,resTable,v.count)
                                end
                            end

                            v.timer = v.duration
                        else
                            v.timer = v.timer - productionWait -- check if res met to decrease timer
                        end
                    else
                        v.toggle = false
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
            Offer()
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

-- Start the loops
parallel.waitForAll(main, second, handleScheduledActions, productionTimer)

-- Code here continues after both loops have exited
print("Both loops have exited.")
