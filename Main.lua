local Monitor = require("Monitor")
local buttonConfig = require("ButtonConfig") -- Load the external button configuration
local currentPage = "settings" -- Default page to start

function drawButtonsForCurrentPage()
    Monitor.clear()
    Monitor.write("Welcome to Town!", 1, 1)
    
    for id, config in pairs(buttonConfig) do
        if config.page == currentPage then
            if config.type == "push" then
                Monitor.drawPushButton(config.label, id, config.x, config.y, config.width, config.height)
            elseif config.type == "line" then
                Monitor.drawButton(config.label, config.icon, id, config.x, config.y, config.position)
            end
        end
    end
end

-- Initialize the monitor and set the default page
Monitor.init()
drawButtonsForCurrentPage()

-- An example function (e.g., inside a button action) to transition to the "settings" page:
function ResourcesPressed()
    currentPage = "settings"
    drawButtonsForCurrentPage()
end

function goToMainPage()
    currentPage = "main"
    buttonConfig.ResourcesButton.enabled = false
    drawButtonsForCurrentPage()
end

-- Event loop remains the same
while true do
    local event, side, x, y = os.pullEvent("monitor_touch")
    local clicked, buttonName = Monitor.isInsideButton(x, y)
    if clicked and buttonConfig[buttonName] and buttonConfig[buttonName].enabled and buttonConfig[buttonName].page == currentPage then
        buttonConfig[buttonName].action()
    end
end
