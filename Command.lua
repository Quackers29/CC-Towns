-- Function to start the computer
function startComputer()
    print("Computer is starting...")
    -- Add your start-up logic here
end

-- Function to stop the computer
function stopComputer()
    print("Computer is stopping...")
    -- Add your shutdown logic here
end

-- Function to reboot the computer
function rebootComputer()
    print("Computer is rebooting...")
    -- Add your reboot logic here
end

-- Main function to handle command-line argument
function main(arg)
    if arg == "Start" then
        startComputer()
    elseif arg == "Stop" then
        stopComputer()
    elseif arg == "Reboot" then
        rebootComputer()
    else
        print("Invalid argument. Please use 'Start', 'Stop', or 'Reboot'.")
    end
end

-- Get command-line argument
local args = { ... }
local command = args[1]

-- Check if a command is provided
if command then
    main(command)
else
    print("Usage: lua program <Start|Stop|Reboot>")
end