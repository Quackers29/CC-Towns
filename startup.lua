local Monitor = require("Monitor")
local Utility = require("Utility")
local waitForControl = 10

term.clear()
term.setCursorPos(1,1)

print("Starting up (Waiting for Server)")
os.sleep(30)

local adminFile = "AdminSettings.json"
local AdminSettings = Utility.readJsonFile(adminFile)
local x,y,z = gps.locate()

--Add a control PC initialisation step if xyz has not been set in the Admin file
--Add a skip step

if AdminSettings then
    if AdminSettings.Admin.ControlPC.x == x and AdminSettings.Admin.ControlPC.y == y and AdminSettings.Admin.ControlPC.z == z then
        term.clear()
        term.setCursorPos(1,1)
        print("This is the control PC")
        if AdminSettings.Admin.ControlPC.AutoUpdate then
            print("Setting Towns to wait for command")
            AdminSettings.Town.Startup = false
            Utility.writeJsonFile(adminFile,AdminSettings)
            print("Updating code from Github Repo") -- IF VERSION CHANGES (FUTURE OPERATION)
            
            shell.run("gitget Quackers29 CC-Towns main") --https://www.computercraft.info/forums2/index.php?/topic/17387-gitget-version-2-release/

            os.sleep(20)
        else
            print("Not Auto-Updating")
        end
        print("Setting Towns to startup")
        os.sleep(2)
        AdminSettings.Town.Startup = true
        Utility.writeJsonFile(adminFile,AdminSettings)
        print("Towns can now startup")
    else
        term.clear()
        term.setCursorPos(1,1)
        print("This is a Town PC, waiting for command to startup")
        os.sleep(30)
        local flag = true
        while flag do
            local AdminSettings = Utility.readJsonFile(adminFile)
            if AdminSettings then
                if AdminSettings.Town.Startup then
                    flag = false
                    print("This is a Town PC, startup command received")
                    os.sleep(10)
                    shell.run("Main.lua")
                else
                    print("No startup command, checked at: ")
                    print(os.date())
                    print("Waiting for: "..waitForControl.." seconds")
                    os.sleep(waitForControl)
                end
            end
        end
    end
else
    term.clear()
    term.setCursorPos(1,1)
    print("No Admin Settings file present, Town PC will startup")
    os.sleep(10)
    shell.run("Main.lua")
end

