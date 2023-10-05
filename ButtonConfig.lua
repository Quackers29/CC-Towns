local ButtonConfig = {
    ResourcesButton = {
        label = "Resources",
        x = 5,
        y = 5,
        width = 10,
        height = 3,
        type = "push",
        enabled = true,
        page = "main",
        action = function()
            goToSettingsPage()
        end
    },
    CloseButton = {
        label = "Close",
        x = 5,
        y = 8,
        type = "line",
        icon = "X",
        position = "right",
        enabled = true,
        page = "settings",
        action = function()
            goToMainPage()
        end
    }
    -- ... other button configurations
}

return ButtonConfig