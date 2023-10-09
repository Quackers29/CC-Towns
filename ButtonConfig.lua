local ButtonConfig = {
    {label = "Upgrades",id = "upgradesButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("upgrades") end},
    {label = "Resources",id = "resourcesButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("resources") end},
    {label = "Trade",id = "tradeButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("settings") end},
    {label = "Contracts",id = "contractsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("settings") end},
    {label = "Stats",id = "statsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("settings") end},
    {label = "Settings",id = "settignsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("settings") end},
    {label = "Bonus",id = "bonusButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("settings") end},
    {label = "Bonus2",id = "bonusButton2",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "main",action = function()    goToPage("settings") end},
    {label = "Back",id = "backButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    goToPage("main") end},
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("main") end,enabled = true, type = "button",page = "resources"},
    {id = "Refresh",width = 3,x = -5,y = 0,colorOn = colors.blue,colorOff = colors.gray,charOn = "A",action = function() RefreshFlag() end,enabled = true, type = "button",page = "resources"},
    {id = "addBtn",justify = "right",width = 3,colorOn = colors.green,colorOff = colors.gray,charOn = "+",action = function() print("Add button pressed!") end,enabled = false, type= "list",page = "resources"},
    {id = "removeBtn",justify = "right",width = 3,colorOn = colors.red,colorOff = colors.gray,charOn = "-",action = function() print("Remove button pressed!") end,enabled = false, type = "list",page = "resources"},
    {id = "toggle",justify = "left",width = 3,colorOn = colors.yellow,colorOff = colors.blue,charOn = "O",action = function(x) handleItem(x) end,enabled = false, type = "list",page = "resources"},
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("main") end,enabled = true, type = "button",page = "upgrades"},
    {id = "toggle",justify = "left",width = 3,colorOn = colors.yellow,colorOff = colors.blue,charOn = "O",action = function(x) handleCSVItem(x) end,enabled = false, type = "list",page = "upgrades"}
}

return ButtonConfig