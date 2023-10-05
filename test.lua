
--local touchpoint = require("touchpoint")
local buttonConfig = require("ButtonConfig") -- Assuming you're using a separate button configuration file
os.loadAPI("touchpoint")
--local monitor = peripheral.find("monitor")
local tp = touchpoint.new("top") -- Create a new Touchpoint instance for our monitor

-- Clear the screen
--monitor.clear()
--monitor.setCursorPos(1, 1)

-- Define and add buttons based on your buttonConfig
for _, config in pairs(buttonConfig) do
    local x2 = config.x + (config.width or 10) - 1 -- Assuming a default width of 10 if not provided
    local y2 = config.y + (config.height or 3) - 1 -- Assuming a default height of 3 if not provided
    
    tp:add(config.label, config.action, config.x, config.y, x2, y2, colors.red, colors.green)
end
tp:draw()


while true do
    local event, p1 = tp:handleEvents(os.pullEvent())
    if event == "button_click" then
      tp:toggleButton(p1)
    end
  end