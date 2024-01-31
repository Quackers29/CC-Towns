-- Function to start the computer
function startComputer()
    print("Towns are starting...")
    local Utility = require("Utility")
    local McAPI   = require("McAPI")
    local adminFile = "AdminSettings.json"
    if Utility and McAPI then
        local Admin = Utility.readJsonFile(adminFile)
        if Admin then
            McAPI.Init(Admin.main.version)
            McAPI.ScoreSet("StartUp", "AllTowns", 1)
        end
    end
end

-- Function to stop the computer
function stopComputer()
    print("Towns are stopping...")
    local Utility = require("Utility")
    local McAPI   = require("McAPI")
    local adminFile = "AdminSettings.json"
    if Utility and McAPI then
        local Admin = Utility.readJsonFile(adminFile)
        if Admin then
            McAPI.Init(Admin.main.version)
            McAPI.ScoreSet("StartUp", "AllTowns", 0)
            McAPI.ScoreSet("Restart", "AllTowns", 1)
        end
    end
end

-- Function to reboot the computer
function rebootComputer()
    print("Towns are rebooting...")
    local Utility = require("Utility")
    local McAPI   = require("McAPI")
    local adminFile = "AdminSettings.json"
    if Utility and McAPI then
        local Admin = Utility.readJsonFile(adminFile)
        if Admin then
            McAPI.Init(Admin.main.version)
            McAPI.ScoreSet("StartUp", "AllTowns", 1)
            McAPI.ScoreSet("Restart", "AllTowns", 1)
        end
    end
end

-- Function to update Stats
function statsComputer()
    print("Updating Stats...")
    local Utility = require("Utility")
    local McAPI   = require("McAPI")
    local adminFile = "AdminSettings.json"
    if Utility and McAPI then
        local Admin = Utility.readJsonFile(adminFile)
        if Admin then
            McAPI.Init(Admin.main.version)
            while true do
                local Alltowns = Utility.FindAllTowns()
                McAPI.ScoreSet("Towns", "AllTowns", #Alltowns)
                os.sleep(10)
            end
        end
    end
end

-- Function to SelfDestruct the town
function SelfDestruct()
    local Utility = require("Utility")
    local townNames = "Defaults\\townNames.json"
    local x,y,z = gps.locate()
    local townFolder = "Town_X"..x.."Y"..y.."Z"..z
    local town = "Towns\\"..townFolder.."\\"
    local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".json"
    local adminFile = "AdminSettings.json"
    Utility.LoadFiles(SettingsFile,adminFile,"")

    print("Computer will Self Destruct in 5 seconds")
    os.sleep(5)
    local townNamesList = Utility.readJsonFile(townNames)
    local Settings = Utility.readJsonFile(SettingsFile)
    if townNamesList and townNamesList.used and Settings and Settings.town.name ~= nil then
        townNamesList.used[Settings.town.name] = nil
        Utility.writeJsonFile(townNames,townNamesList)
    end
    Utility.SelfDestruct()
end

local function RandomGen()
    local Utility = require("Utility")
    local McAPI     = require("McAPI")
    local adminFile = "AdminSettings.json"
    local x,y,z = gps.locate()

    while true do
        local Alltowns = Utility.FindAllTowns()
        if #Alltowns > 0 then
            local RandomTown = Alltowns[math.random(1, #Alltowns)]
            local Admin = Utility.readJsonFile(adminFile)
            local result, message, score = commands.scoreboard.players.get("GenState", "AllTowns")
            if Admin and score == 2 then
                local OpLocation = Utility.findNewTownLocation(Utility.FindOtherTowns(RandomTown.folderName), Admin.generation.minDistance,Admin.generation.maxDistance, {x = RandomTown.x, z = RandomTown.z}, Admin.generation.spread)
                if OpLocation then
                    Utility.SpawnTown(OpLocation.x,OpLocation.y,OpLocation.z,McAPI.GetComputerId(x, y, z))
                    os.sleep(60)
                end
            end
            if Admin and score == 3 then
                local result, message, score = commands.exec("list")
                local playerList = {}
                if result then
                    -- Splitting the string at ': ' to isolate the player names
                    function ExtractPlayerNames(inputstr)
                        local names = {}
                        local pattern = "online: (.+)$"
                        local players = string.match(inputstr, pattern)
                        if players then
                            for name in string.gmatch(players, "([^, ]+)") do
                                table.insert(names, name)
                            end
                        end
                        return names
                    end
                    playerList = ExtractPlayerNames(message[1])
                end

                if #playerList > 0 then
                    for i,v in ipairs(playerList) do
                        local result, message, score = commands.scoreboard.players.get(v, "useCarrot")
                        if score > 0 then
                            local a,b,c = commands.data.get.entity(v)
                            local c= b[1]
                            local d=string.match(c, 'Pos:.-.]')
                            local xa,ya,za = string.match(d, "(%--%d*%.?%d+).,.(%--%d*%.?%d+).,.(%--%d*%.?%d+)")
                            local xa,ya,za = Utility.round(xa),Utility.round(ya),Utility.round(za)
                            
                            local result, message, score = commands.data.get.entity(v,"Dimension")
                            local result1, message1, score1 = commands.data.get.entity(v,"playerGameType")
                            if score1 == 1 and string.match(message[1],"minecraft:overworld") then
                                Utility.SpawnTown(xa,ya,za,McAPI.GetComputerId(x, y, z))
                            end
                        end
                    end
                    commands.exec("scoreboard players reset * useCarrot")
                end
            end
        end
        os.sleep(10)
    end
end

function Install()
    --get json
    shell.run("pastebin get 4nRg9CHU json")
    --get gitget
    shell.run("pastebin get W5ZkVYSi gitget")
    --use gitget to get repo
    shell.run("gitget Quackers29 CC-Towns main")
    --reboot
    print("Rebooting...")
    os.sleep(2)
    os.reboot()
end

function Update()
    shell.run("gitget Quackers29 CC-Towns main")
end

function ChangeName(newName)
    local Utility = require("Utility")
    local x,y,z = gps.locate()
    local townFolder = "Town_X"..x.."Y"..y.."Z"..z
    local town = "Towns\\"..townFolder.."\\"
    local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".json"
    local adminFile = "AdminSettings.json"
    Utility.LoadFiles(SettingsFile,adminFile,"")
    Utility.ChangeName(newName)
    os.reboot()
end

function EditSettings()
    local x,y,z = gps.locate()
    local townFolder = "Town_X"..x.."Y"..y.."Z"..z
    local town = "Towns\\"..townFolder.."\\"
    local SettingsFile = town.."SET_X"..x.."Y"..y.."Z"..z..".json"
    shell.run("edit "..SettingsFile)
end

-- Main function to handle command-line argument
function main(arg1, arg2)
    if arg1 == "start" then
        startComputer()
    elseif arg1 == "stop" then
        stopComputer()
    elseif arg1 == "reboot" then
        rebootComputer()
    elseif arg1 == "stats" then
        statsComputer()
    elseif arg1 == "remove" then
        SelfDestruct()
    elseif arg1 == "generation" then
        RandomGen()
    elseif arg1 == "install" then
        Install()
    elseif arg1 == "update" then
        Update()
    elseif arg1 == "edit" then
        EditSettings()
    elseif arg1 == "name" then
        if arg2 ~= "" or arg2 ~= nil then
            ChangeName(arg2)
        end
    else
        print("Invalid argument. Please use '<start|stop|reboot|stats|remove|generation|install|update|edit>'.")
    end
end

-- Get command-line argument
local args = { ... }
local arg1 = args[1]
local arg2 = args[2]

-- Check if a command is provided
if arg1 then
    main(arg1, arg2)
else
    print("Usage: lua program <start|stop|reboot|stats|remove|generation|install|update|edit>")
end