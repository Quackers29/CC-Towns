local ButtonConfig = {
    {
        label = "Upgrades",
        id = "upgradesButton",
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
    {
        label = "Resources",
        id = "resourcesButton",
        x = 5,
        y = 8,
        type = "push",
        icon = "X",
        position = "right",
        enabled = true,
        page = "main",
        action = function()
            goToSettingsPage()
        end
    },
    {
        label = "Trade",
        id = "tradeButton",
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
    {
        label = "Contracts",
        id = "contractsButton",
        x = 5,
        y = 8,
        type = "push",
        icon = "X",
        position = "right",
        enabled = true,
        page = "main",
        action = function()
            goToSettingsPage()
        end
    },
    {
        label = "Stats",
        id = "statsButton",
        x = 5,
        y = 8,
        type = "push",
        icon = "X",
        position = "right",
        enabled = true,
        page = "main",
        action = function()
            goToSettingsPage()
        end
    },
    {
        label = "Settings",
        id = "settignsButton",
        x = 5,
        y = 8,
        type = "push",
        icon = "X",
        position = "right",
        enabled = true,
        page = "main",
        action = function()
            goToSettingsPage()
        end
    },
    {
        label = "Bonus",
        id = "bonusButton",
        x = 5,
        y = 8,
        type = "push",
        icon = "X",
        position = "right",
        enabled = true,
        page = "main",
        action = function()
            goToSettingsPage()
        end
    },
    {
        label = "Bonus2",
        id = "bonusButton2",
        x = 5,
        y = 8,
        type = "push",
        icon = "X",
        position = "right",
        enabled = true,
        page = "main",
        action = function()
            goToSettingsPage()
        end
    },
    {
        label = "Back",
        id = "backButton",
        x = 5,
        y = 8,
        type = "push",
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