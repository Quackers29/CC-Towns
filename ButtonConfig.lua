local ButtonConfig = {
    {label = "Upgrades",id = "upgradesButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToSettingsPage() end},
    {label = "Resources",id = "resourcesButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToResourcesPage() end},
    {label = "Trade",id = "tradeButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToSettingsPage() end},
    {label = "Contracts",id = "contractsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToSettingsPage() end},
    {label = "Stats",id = "statsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToSettingsPage() end},
    {label = "Settings",id = "settignsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToSettingsPage() end},
    {label = "Bonus",id = "bonusButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToSettingsPage() end},
    {label = "Bonus2",id = "bonusButton2",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToSettingsPage() end},
    {label = "Back",id = "backButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    goToMainPage() end},
    {id = "addBtn",justify = "right",width = 3,colorOn = colors.green,colorOff = colors.gray,charOn = "+",action = function() print("Add button pressed!") end,enabled = false, type= list,page = "resources"},
    {id = "removeBtn",justify = "right",width = 3,colorOn = colors.red,colorOff = colors.gray,charOn = "-",action = function() print("Remove button pressed!") end,enabled = false, type = list,page = "resources"},
    {id = "toggle",justify = "left",width = 3,colorOn = colors.yellow,colorOff = colors.blue,charOn = "O",action = function(x) handleItem(x) end,enabled = false, type = list,page = "resources"}
}

return ButtonConfig