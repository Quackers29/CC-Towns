local Monitor   = require("Monitor")
local Utility   = require("Utility")
local TradeAPI  = require("TradeAPI")
local McAPI     = require("McAPI")
local buttonConfig = require("ButtonConfig")
local currentPage = "Main" -- Default page to start
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
local townNames = "Defaults\\townNames.json"
local townNamesSource = "Defaults\\townNamesSource.json"
local mainflag = true
local productionWait = 10
local mainWait = 10 -- MainLoop
local refreshflag = true
local displayItem = nil
local LastX,LastY = 1,1 -- use for map coordinates
local adminFile = "AdminSettings.json"
local currentZoom = 1 -- 1 for 1
local minWidth = 8
local minHeight = 2
local townName = nil
local scheduledActions = {} -- keeps track of scheduled actions
local facing = McAPI.GetFacing(x,y,z)

-- Initialize Utility program with correct filepaths

Utility.LoadFiles(SettingsFile,adminFile,resFile)

-- Initialize Checks if it exists or should exist

local TownFlag = Utility.IsATown(townFolder)

local Admin = Utility.readJsonFile(adminFile)
if Admin and Admin.town.minDistance then
    local deleteTown = false
    if not TownFlag then
        print("Town does not already exist")
        for i,v in ipairs(fs.list("Towns")) do
            local ax, ay, az = string.match(v, "X(%-?%d+)Y(%-?%d+)Z(%-?%d+)")
            if Utility.IsInRange2DAngular(ax, az, x, z, Admin.town.minDistance) then
                print("NewTown is within another Town, deleting Computer")
                os.sleep(10)
                McAPI.setBlock(x,y,z,"cobblestone")
                error("Program terminated, Computer deleted")
                break
            end
        end
    end
end

-- Initialise McAPI with version number
if Admin and Admin.main.version then
    McAPI.Init(Admin.main.version)
end

-- Initialize checks / file system

Utility.CopyIfMissing(defaultSettingsFile,SettingsFile)
Utility.CopyIfMissing(tradeSource,tradeFile)

Utility.InitInOut(x,y,z)

local Settings = Utility.readJsonFile(SettingsFile)

if Settings and Admin then
    -- Biome search
    if Settings.general.biome == nil and Admin.generation.biomeCheck then
        local currentBiome = nil
        local dist = 9999
        if not fs.exists(biomeFile) then
            local biomeslist = Utility.readCSV(biomes)
            local newList = {}
            for i,v in pairs(biomeslist) do
                print(i,v)
                print(v.id)
                local listItem = {}
                local boolean, tableWithString, distance = McAPI.LocateBiome(v.id)
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
        if currentBiome == nil then
            currentBiome = "none"
        else
            currentBiome = currentBiome:match("_(.*)$") or currentBiome
        end
        Settings.general.biome = currentBiome or "none"
        Settings.general.biomeDist = dist or nil
    end

    if Settings.town.name == nil then

        -- Builds the Monitor
        if Admin.generation.monitorBuild == true then
            Utility.buildMonitor(x,y,z)
            Utility.BuildInOut(facing)
        end

        -- Town name search
        local townNamesList = nil
        if not fs.exists(townNames) then
            local townNamesListSource = Utility.readJsonFile(townNamesSource)
            if townNamesListSource then
                townNamesList = {}
                townNamesList["used"] = {}
                townNamesList["available"] = townNamesListSource["available"]
            end
        else
            townNamesList = Utility.readJsonFile(townNames)
        end
        
        local foundName = false
        townName = nil
        if townNamesList then
            --Get a new name list if no more names available
            if #townNamesList.available == 0 then
                local townNamesListSource = Utility.readJsonFile(townNamesSource)
                if townNamesListSource then
                    townNamesList["available"] = townNamesListSource["available"]
                end
            end


            local randomIndex = math.random(1, #townNamesList.available)
            townName = townNamesList.available[randomIndex]
            table.remove(townNamesList.available,randomIndex)
            if townNamesList.used[townName] then
                for x = 2,5 do
                    if not townNamesList.used[townName..x] then
                        townName = townName..x
                        foundName = true
                        break
                    end
                end
            else
                foundName = true
            end


            if foundName then
                townNamesList.used[townName] = townFolder
            end
            Utility.writeJsonFile(townNames,townNamesList)
        end
        if not foundName then
            McAPI.SayNear("No town name available, deleting town: "..townFolder,x,y,z,500)
            Utility.SelfDestruct()
        end

        Settings.town.name = townName
        Settings.town.born = Utility.GetTime("%Y-%m-%d %H:%M:%S", os.epoch("utc"))
        Settings.town.timestamp = os.epoch("utc") -- milliseconds
        print(townName)
        print("Created: "..Utility.GetTime("", Settings.town.timestamp))
        McAPI.Say("New Town: "..townName.." ("..x..","..y..","..z.."). Founded: "..Utility.GetTime("", Settings.town.timestamp))
        Utility.Fireworks()
    else
        townName = Settings.town.name
    end

    --Add restart timer to settings file
    Settings.lastRestarted = os.epoch("utc")
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

-- Main Display function, changes display based on the 'currentPage' variable
function DrawButtonsForCurrentPage()
    Monitor.init()
    Settings = Utility.readJsonFile(SettingsFile)
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

    if Settings then
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
            local INx,INy,INz = Settings.resources.input.x,Settings.resources.input.y,Settings.resources.input.z
            Monitor.write("Settings - Input Chest!", 1, 1, colors.white)
            Monitor.write("X: "..INx.." Y: "..INy.." Z: "..INz,1, 5, colors.white)
            Utility.ParticleMarker(INx, INy, INz)
            for i,v in ipairs(pageButtons["button"]) do

                Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
            end

        elseif currentPage == "settings_OutputChest" then
            local OUTx,OUTy,OUTz = Settings.resources.output.x,Settings.resources.output.y,Settings.resources.output.z
            Monitor.write("Settings - Output Chest!", 1, 1, colors.white)
            Monitor.write("X: "..OUTx.." Y: "..OUTy.." Z: "..OUTz,1, 5, colors.white)
            Utility.ParticleMarker(OUTx, OUTy, OUTz)
            for i,v in ipairs(pageButtons["button"]) do
                Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
            end

        elseif currentPage == "settings_InputPop" then
            local PINx,PINy,PINz = Settings.tourist.input.x,Settings.tourist.input.y,Settings.tourist.input.z
            Monitor.write("Settings - Input Pop!", 1, 1, colors.white)
            Monitor.write("X: "..PINx.." Y: "..PINy.." Z: "..PINz.." Radius: "..Settings.tourist.input.radius,1, 5, colors.white)
            Utility.ParticleMarker(PINx, PINy, PINz)
            for i,v in ipairs(pageButtons["button"]) do
                Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
            end

        elseif currentPage == "settings_OutputPop" then
            local POUTx,POUTy,POUTz = Settings.tourist.output.x,Settings.tourist.output.y,Settings.tourist.output.z
            local POUTx2,POUTy2,POUTz2 = Settings.tourist.output.x2,Settings.tourist.output.y2,Settings.tourist.output.z2

            Monitor.write("Settings - Output Pop!", 1, 1, colors.white)
            Monitor.write("X: "..POUTx.." Y: "..POUTy.." Z: "..POUTz,1, 5, colors.white)
            Utility.ParticleMarker(POUTx, POUTy, POUTz)

            if Settings.tourist.output.method == "Line" then
                Monitor.write("X: "..POUTx2.." Y: "..POUTy2.." Z: "..POUTz2,1, 13, colors.white)
                Utility.ParticleMarker(POUTx2, POUTy2, POUTz2)
                for i,v in ipairs(pageButtons["button2"]) do
                    Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
                end
            end

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
            Monitor.displayMap(Utility.FindOtherTowns(townFolder), currentTown, topLeftX, topLeftY, mapWidth, mapHeight, currentZoom)
            Monitor.write("o",LastX,LastY)

        elseif currentPage == "display_upgrade" then
            local canUp = true
            local resTable = Utility.readJsonFile(resFile)
            local displayTable = Utility.readJsonFile(upgradesFile)
            Monitor.write("Upgrade: "..(displayItem.key or ""), 1, 1)
            Monitor.write("duration: "..(displayItem.duration or ""), 10, 2)
            Monitor.write("Cost: ", 10, 3)
            Monitor.write("Prerequisites: ", 10, ((endY-2)/2)+4)
            local index = 1
            local costTable = {}
            local PreRecTable = {}
            if type(displayItem.requires) ~= "table" then
                displayItem.requires ={displayItem.requires}
            end

            if displayItem and displayTable and displayItem.requires then
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
                Monitor.drawKeyList(Utility.round(((endY-2)/2)+4), endY, PreRecTable, pageButtons["list"], 1, 1) 
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
            Monitor.drawKeyList(4,Utility.round(((endY-2)/2)+2), costTable, pageButtons["list"], 1, 0)

            for i,v in ipairs(pageButtons["button"]) do
                if v.id == "Up" then
                    v.enabled = canUp
                    v.item = displayItem
                end
                Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
            end

        elseif currentPage == "Trade_Trading" then
            Monitor.write("Trading", 1, 1)
            Monitor.write("Buying: ", 10, 3)
            Monitor.write("Selling: ", 10, ((endY-2)/2)+4)
            local tradeTable = Utility.readJsonFile(tradeFile)
            if tradeTable then
                local PreRecTable = {}
                if tradeTable.proposal then
                    for i,v in pairs(tradeTable.proposal) do --
                        PreRecTable[v.item] = PreRecTable[v.item] or {}
                        PreRecTable[v.item]["key"] = v.item
                        PreRecTable[v.item]["extra"] = " x"..v.needed
                        PreRecTable[v.item]["toggle"] = false
                        PreRecTable[v.item]["string"] = v.item
                    end
                    Monitor.drawKeyList(4, Utility.round(((endY-2)/2)+2), PreRecTable, pageButtons["list"], 1, 0)
                end 
                PreRecTable = {}
                if tradeTable.selling then
                    for i,v in pairs(tradeTable.selling) do --
                        PreRecTable[v.item] = PreRecTable[v.item] or {}
                        PreRecTable[v.item]["key"] = v.item
                        PreRecTable[v.item]["extra"] = " x"..v.maxQuantity
                        PreRecTable[v.item]["toggle"] = false
                        PreRecTable[v.item]["string"] = v.item
                    end
                    Monitor.drawKeyList(Utility.round(((endY-2)/2)+4), endY, PreRecTable, pageButtons["list"], 1, 1)
                end 
            end
            for i,v in ipairs(pageButtons["button"]) do
                Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
            end

        elseif currentPage == "Trade_History" then
            Monitor.write("History", 1, 1)
            Monitor.write("Bought: ", 10, 3)
            Monitor.write("Sold: ", 10, ((endY-2)/2)+4)
            local tradeTable = Utility.readJsonFile(tradeFile)
            if tradeTable then
                local PreRecTable = {}
                if tradeTable.bought then
                    for i,v in pairs(tradeTable.bought) do --
                        -- key gets overwritten with [i] so fix or 
                        local id = Utility.GetTime("%m-%d %H:%M ", v.timeAccepted)..v.item
                        PreRecTable[id] = PreRecTable[i] or {}
                        PreRecTable[id]["key"] = Utility.GetTime("%m-%d %H:%M ", v.timeAccepted)..v.item
                        PreRecTable[id]["extra"] = " x"..v.needed
                        PreRecTable[id]["toggle"] = false
                        PreRecTable[id]["string"] = Utility.GetTime("%m-%d %H:%M ", v.timeAccepted)..v.item
                    end
                    Monitor.drawKeyList(4, Utility.round(((endY-2)/2)+2), PreRecTable, pageButtons["list"], 1, 0)
                end 
                PreRecTable = {}
                if tradeTable.sold then
                    for i,v in pairs(tradeTable.sold) do --
                        local id = Utility.GetTime("%m-%d %H:%M ", v.timeAccepted)..v.item
                        PreRecTable[id] = PreRecTable[i] or {}
                        PreRecTable[id]["key"] = Utility.GetTime("%m-%d %H:%M ", v.timeAccepted)..v.item
                        PreRecTable[id]["extra"] = " x"..v.needed
                        PreRecTable[id]["toggle"] = false
                        PreRecTable[id]["string"] = Utility.GetTime("%m-%d %H:%M ", v.timeAccepted)..v.item
                    end
                    Monitor.drawKeyList(Utility.round(((endY-2)/2)+4), endY, PreRecTable, pageButtons["list"], 1, 1)
                end
            end
            for i,v in ipairs(pageButtons["button"]) do
                Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
            end

        elseif Settings and currentPage == "Tourists_Settings" then
            Monitor.write("Tourists Settings", 1, 1)
            Monitor.write("Tourist Auto Input", 5, 3)
            Monitor.write("Tourist Auto Output", 5, 6)
            Monitor.write("Set Input", 5, 4)
            Monitor.write("Set Output", 5, 7)
            local output = false
            local input = false
            if Settings.tourist.touristOutput then
                output = true
            end
            if Settings.tourist.autoInput then
                input = true
            end

            for i,v in ipairs(pageButtons["button"]) do
                if v.id == "touristOutput" then
                    v.enabled = output
                elseif v.id == "autoInput" then
                    v.enabled = input
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
            Monitor.write("Prerequisites: ", 10, ((endY-2)/2)+4)
            local index = 1
            local costTable = {}
            local PreRecTable = {}
            if type(displayItem.requires) ~= "table" then
                displayItem.requires = {displayItem.requires}
            end

            if displayTable and displayItem.requires then
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
                Monitor.drawKeyList(Utility.round(((endY-2)/2)+4), endY, PreRecTable, pageButtons["list"], 1, 1) 
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
            Monitor.drawKeyList(4, Utility.round(((endY-2)/2)+2), costTable, pageButtons["list"], 1, 0)

            for i,v in ipairs(pageButtons["button"]) do
                if v.id == "Up" then
                    v.enabled = canUp
                    v.item = displayItem
                end
                Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
            end

        elseif currentPage == "Tourists_History" then
            -- timestamp keys are already in order, oldest first so reverse it
            -- Collect keys into a table
            local keys = {}
            for key in pairs(Settings.tourist.History) do
                table.insert(keys, tonumber(key))
            end

            Monitor.write("History of Tourists to "..Settings.town.name.."!", 1, 1)
            local PreRecTable = {}
            if Settings then    
                for i = #keys, 1, -1 do
                    local key = keys[i]
                    local value = Settings.tourist.History[tostring(key)]

                    -- key gets overwritten with [i] so fix or 
                    local id = Utility.GetTime("%m-%d %H:%M:%S ", key)
                    PreRecTable[id] = PreRecTable[i] or {}
                    PreRecTable[id]["key"] = Utility.GetTime("%m-%d %H:%M:%S ", key)
                    PreRecTable[id]["extra"] = value
                    PreRecTable[id]["toggle"] = false
                    PreRecTable[id]["string"] = Utility.GetTime("%m-%d %H:%M:%S ", key)..value
                end
                Monitor.drawKeyList(3, endY-1, PreRecTable, pageButtons["list"], 1, 0)
                for i,v in ipairs(pageButtons["button"]) do
                    Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
                end
            end
        else
            -- Add back to Main button if no buttons assigned to page
            Monitor.write("Welcome to "..Settings.town.name.."! - "..currentPage.." T:("..Settings.tourist.touristCurrent..")", 1, 1, colors.white)
            if pageButtons == {} or pageButtons["push"] == nil then
                Monitor.drawButton(Monitor.OffsetCheck(-1, endX),Monitor.OffsetCheck(0, endY),{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Main") end,enabled = true, type = "button",page = "all"})
            else
                Monitor.drawFlexibleGrid(startX, startY, endX, endY, minWidth, minHeight, pageButtons["push"])
            end
            if pageButtons["button"] then
                for i,v in ipairs(pageButtons["button"]) do
                    Monitor.drawButton(Monitor.OffsetCheck(v.x, endX),Monitor.OffsetCheck(v.y, endY),v)
                end
            end
        end
    end
end


-- Initialize the monitor and set the default page
Monitor.init()
DrawButtonsForCurrentPage()

function goToPage(x)
    Monitor.initList()
    currentPage = x
    Monitor.OffsetButton(0)
    DrawButtonsForCurrentPage()
end

function goToDisplayPage(x, todisplay)
    Monitor.initList()
    displayItem = x.item
    currentPage = todisplay
    DrawButtonsForCurrentPage()
end

function OffsetButton(x,y)
    Monitor.OffsetButton(x,y)
    DrawButtonsForCurrentPage()
end

function OffsetZoom(x)
    currentZoom = math.max((currentZoom + x),1)
    DrawButtonsForCurrentPage()
end

function OutputPOP()
    Utility.OutputPop(1,townName)
end

function InputPOP()
    Utility.InputPop("",townNames,x,z)
end

function InputMultiTourists()
    Utility.MultiTouristInput(townName,townNames,x,z)
end

function OutputTourist()
    Utility.OutputTourist(1, townName)
end

function InputAllOwnTourists()
    Utility.InputAllOwnTourists()
end

function Refresh()
    DrawButtonsForCurrentPage()
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
    DrawButtonsForCurrentPage()
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
    DrawButtonsForCurrentPage()
end

function handlePop(x)
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings then
        if Settings.tourist[x] == false then
            Settings.tourist[x] = true
        else
            Settings.tourist[x] = false
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
    DrawButtonsForCurrentPage()
end

function handlePopMethod()
    local Settings = Utility.readJsonFile(SettingsFile)
    if Settings then
        if Settings.tourist.output.method == "Point" then
            Settings.tourist.output.method = "Line"
        else
            Settings.tourist.output.method = "Point"
        end
        Utility.writeJsonFile(SettingsFile,Settings)
    end
    DrawButtonsForCurrentPage()
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
        DrawButtonsForCurrentPage()
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
        DrawButtonsForCurrentPage()
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

--Specific monitor pages will refresh on a faster loop
function MonitorLoop()
    while mainflag do
        if currentPage == "Map" or currentPage == "resources" or currentPage == "display_upgrade" or currentPage == "display_production" or string.match(currentPage, "^Trade") ~= nil then
            DrawButtonsForCurrentPage()
            if Admin then
                os.sleep(Admin.town.monitorRefresh)
            end
        else
            os.sleep(mainWait)
        end
    end
end

function ChestLoop()
    while mainflag do
        Settings = Utility.readJsonFile(SettingsFile)
        if Settings and Admin and refreshflag then
            local INx,INy,INz = Settings.resources.input.x,Settings.resources.input.y,Settings.resources.input.z
            local OUTx,OUTy,OUTz = Settings.resources.output.x,Settings.resources.output.y,Settings.resources.output.z
            if Admin.main.version == 1 then
                Utility.inputItems(INx,INy,INz,-64)
            else
                Utility.inputItems(INx,INy,INz,0)
            end
            Utility.checkItems(OUTx,OUTy,OUTz)
            os.sleep(Admin.town.chestRefresh)
        else
            os.sleep(mainWait)
        end
    end
end

-- decreases a timer, need to change to timestamps
-- rewrite needed
function ProductionCheck()
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

-- ScoreLoop checks the scoreboard to see if a player sets a score for All [Restart] to 1 
-- could instead use timestamps but score can only go up to 999999999, 9 digits. 
-- example timestamp is "timestamp": 1700144675566, 13 digits
-- So admin could set the start of server time to in settings and the score only be the difference giving 9 digits of time...
function CheckRestart()
    if Settings and Admin then
        if Settings.lastRestarted < Admin.town.restart then
            --Reboot the Town
            Monitor.clear()
            Monitor.write("Offline",1,1)
            Shutdown()
        end
    end
end

-- Function to handle scheduled actions
-- Replace with TIMESTAMPS in future maybe
function HandleScheduledActionsLoop()
    while mainflag do
        local event, timerID = os.pullEvent("timer")
        if scheduledActions[timerID] then
            scheduledActions[timerID]()  -- Execute the scheduled action
            scheduledActions[timerID] = nil  -- Remove the action from the table
        end
    end
end

-- Event loop reMains the same
function MonitorEventsLoop()
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

function MainLoop()
    while mainflag do
        Admin = Utility.readJsonFile(adminFile)
        if Admin then
            mainWait = Admin.town.mainWait
            if Admin.main.packages.production then
                ProductionCheck()
            end
            if Admin.main.packages.trade then
                TradeAPI.SellerUpdateOffers(tradeFile,SettingsFile,resFile)
                TradeAPI.BuyerSearchOffers(Utility.FindOtherTowns(townFolder),townFolder,tradeFile,SettingsFile,resFile)
                TradeAPI.SellerCheckResponses(tradeFile,townFolder,resFile)
                TradeAPI.BuyerMonitorAuction(tradeFile,resFile)
                TradeAPI.BuyerMonitorAccepted(tradeFile,resFile)
            end
            if Admin.main.packages.population then
                Utility.PopGen(Admin.population.upkeep,Admin.population.generationCost)
            end
            if Admin.main.packages.tourist then
                if Admin.tourist.genCostEnabled then
                    Utility.TouristGenCost()
                else
                    Utility.TouristGen()
                end
                Utility.TouristTransfer(1, townName,townNames,x,y)
            end
            DrawButtonsForCurrentPage()
        end
        os.sleep(mainWait)
    end
end

-- commands.scoreboard.objectives.add("AllTowns","dummy") Added to Startup Control PC
function AdminLoop()
    while mainflag do
        Admin = Utility.readJsonFile(adminFile)
        CheckRestart()
        local wait =  60
        if Admin then
            wait = Admin.town.adminWait
            --Control Methods: none, all, pc, score
            if Admin.main.controlMethod == "all" or Admin.main.controlMethod == "score" then
                if McAPI.ScoreGet("SelfDestruct", "AllTowns") == 1 then
                    local townNamesList = Utility.readJsonFile(townNames)
                    if townNamesList and townNamesList.used and Settings then
                        townNamesList.used[Settings.town.name] = nil
                        Utility.writeJsonFile(townNames,townNamesList)
                    end
                    Monitor.clear()
                    Utility.SelfDestruct()
                end
                
                if McAPI.ScoreGet("Restart", "AllTowns") == 1 then
                    McAPI.ScoreSet("Restart", "AllTowns", 0)
                    Admin.town.restart = os.epoch("utc")
                    Utility.writeJsonFile(adminFile,Admin)
                    Monitor.clear()
                    Monitor.write("Offline",1,1)
                    Shutdown()
                end
    
                if Admin.main.packages.generation and McAPI.ScoreGet("GenState", "AllTowns") == 1 then
                    local OpLocation = Utility.findNewTownLocation(Utility.FindOtherTowns(townFolder), Admin.generation.minDistance,Admin.generation.maxDistance, {x = x, z = z}, Admin.generation.spread)
                    if OpLocation then
                        Utility.SpawnTown(OpLocation.x,OpLocation.y,OpLocation.z,McAPI.GetComputerId(x, y, z))
                        os.sleep(60)
                    end
                end
            end
        end
        os.sleep(wait)
    end
end

-- Complete shutdown of all loops
function Shutdown()
    mainflag = false
end

-- Start the loops
parallel.waitForAll(MonitorEventsLoop, ChestLoop, MonitorLoop, HandleScheduledActionsLoop, MainLoop, AdminLoop)

-- Code here continues after loops have exited
print("Loops have exited.")
os.reboot()
