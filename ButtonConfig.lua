local ButtonConfig = {
    {label = "Upgrades",id = "upgradesButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("upgrades") end},
    {label = "Resources",id = "resourcesButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("resources") end},
    {label = "Production",id = "productionButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("production") end},
    {label = "Trade",id = "tradeButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("Trade") end},
    {label = "Contracts",id = "contractsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("Contracts") end},
    {label = "Pop",id = "popButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("Pop") end},
    {label = "Settings",id = "settignsButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("settings") end},
    {label = "Map",id = "mapButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Main",action = function()    goToPage("Map") end},
    {label = "Back",id = "backButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    goToPage("Main") end},
--resources
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Main") end,enabled = true, type = "button",page = "resources"},
    {id = "Refresh",width = 3,x = -5,y = 0,colorOn = colors.blue,colorOff = colors.gray,charOn = "A",action = function() RefreshFlag() end,enabled = true, type = "button",page = "resources"},
    {id = "addBtn",justify = "right",width = 3,colorOn = colors.green,colorOff = colors.gray,charOn = "+",action = function() print("Add button pressed!") end,enabled = false, type= "list",page = "resources"},
    {id = "removeBtn",justify = "right",width = 3,colorOn = colors.red,colorOff = colors.gray,charOn = "-",action = function() print("Remove button pressed!") end,enabled = false, type = "list",page = "resources"},
    {id = "toggle",justify = "left",width = 3,colorOn = colors.yellow,colorOff = colors.blue,charOn = "O",action = function(x) handleItem(x) end,enabled = false, type = "list",page = "resources"},
--upgrades
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Main") end,enabled = true, type = "button",page = "upgrades"},
    {id = "toggle",justify = "left",width = 3,colorOn = colors.yellow,colorOff = colors.blue,charOn = "O",enabled = false, type = "list",page = "upgrades"},
    {id = "addBtn",justify = "right",width = 3,colorOn = colors.green,colorOff = colors.gray,charOn = "+",action = function(x) goToDisplayPage(x,"display_upgrade") end,enabled = true, type= "list",page = "upgrades"},
--display upgrades
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("upgrades") end,enabled = true, type = "button",page = "display_upgrade"},
    {id = "Up",width = 3,x = -1,y = 1,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function(x) UpgradeSchedule(x) goToPage("upgrades") if x.enabled then adjustItems(x) end end,enabled = false, type = "button",page = "display_upgrade"},
    {id = "toggle",justify = "right",width = 3,colorOn = colors.green,colorOff = colors.gray,charOn = "+",enabled = true, type= "list",page = "display_upgrade"},
--production
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Main") end,enabled = true, type = "button",page = "production"},
    {id = "toggle",justify = "left",width = 3,colorOn = colors.yellow,colorOff = colors.blue,charOn = "O",enabled = false, type = "list",page = "production"},
    {id = "addBtn",justify = "right",width = 3,colorOn = colors.green,colorOff = colors.gray,charOn = "+",action = function(x) goToDisplayPage(x,"display_production") end,enabled = true, type= "list",page = "production"},
--display production
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("production") end,enabled = true, type = "button",page = "display_production"},
    {id = "Up",width = 3,x = -1,y = 1,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function(x) handleProduction(x) goToPage("production") end,enabled = false, type = "button",page = "display_production"},
    {id = "toggle",justify = "right",width = 3,colorOn = colors.green,colorOff = colors.gray,charOn = "+",enabled = true, type= "list",page = "display_production"},
--Map
    {id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Main") end,enabled = true, type = "button",page = "Map"},
    {id = "Add",type = "button",page = "Map",width = 3,x = -4,y = 0,action = function() OffsetZoom(-1) end,charOn = "+",colorOn = colors.yellow,colorOff = colors.gray,enabled = true},
    {id = "Subtract",type = "button",page = "Map",width = 3,x = -7,y = 0,action = function() OffsetZoom(1) end,charOn = "-",colorOn = colors.yellow,colorOff = colors.gray,enabled = true},
--Settings
{label = "InputChest",id = "settings_inputchestButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    goToPage("settings_InputChest") end},
{label = "OutputChest",id = "settings_outputchestButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    goToPage("settings_OutputChest") end},
{label = "InputPop",id = "settings_inputPopButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    goToPage("settings_InputPop") end},
{label = "OutputPop",id = "settings_outputPopButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    goToPage("settings_OutputPop") end},
{label = "InPOP",id = "settings_inputPOPButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    InputPOP() end},
{label = "OutPOP",id = "settings_outputPOPButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    OutputPOP() end},
{label = "OutTourist",id = "settings_outputTORButton",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "settings",action = function()    OutputTourist() end},

{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("settings") end,enabled = true, type = "button",page = "settings_InputChest"},
{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("settings") end,enabled = true, type = "button",page = "settings_OutputChest"},
{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("settings") end,enabled = true, type = "button",page = "settings_InputPop"},
{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("settings") end,enabled = true, type = "button",page = "settings_OutputPop"},
--InputChest
{id = "Add",width = 3,x = 2,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeInputChest(1,0,0) end,enabled = true, type = "button",page = "settings_InputChest"},
{id = "Subtract",width = 3,x = 2,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeInputChest(-1,0,0) end,enabled = true, type = "button",page = "settings_InputChest"},
{id = "Add",width = 3,x = 8,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeInputChest(0,1,0) end,enabled = true, type = "button",page = "settings_InputChest"},
{id = "Subtract",width = 3,x = 8,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeInputChest(0,-1,0) end,enabled = true, type = "button",page = "settings_InputChest"},
{id = "Add",width = 3,x = 14,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeInputChest(0,0,1) end,enabled = true, type = "button",page = "settings_InputChest"},
{id = "Subtract",width = 3,x = 14,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeInputChest(0,0,-1) end,enabled = true, type = "button",page = "settings_InputChest"},
--OutputChest
{id = "Add",width = 3,x = 2,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputChest(1,0,0) end,enabled = true, type = "button",page = "settings_OutputChest"},
{id = "Subtract",width = 3,x = 2,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputChest(-1,0,0) end,enabled = true, type = "button",page = "settings_OutputChest"},
{id = "Add",width = 3,x = 8,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputChest(0,1,0) end,enabled = true, type = "button",page = "settings_OutputChest"},
{id = "Subtract",width = 3,x = 8,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputChest(0,-1,0) end,enabled = true, type = "button",page = "settings_OutputChest"},
{id = "Add",width = 3,x = 14,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputChest(0,0,1) end,enabled = true, type = "button",page = "settings_OutputChest"},
{id = "Subtract",width = 3,x = 14,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputChest(0,0,-1) end,enabled = true, type = "button",page = "settings_OutputChest"},
--InputPop
{id = "Add",width = 3,x = 2,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeInputPop(1,0,0) end,enabled = true, type = "button",page = "settings_InputPop"},
{id = "Subtract",width = 3,x = 2,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeInputPop(-1,0,0) end,enabled = true, type = "button",page = "settings_InputPop"},
{id = "Add",width = 3,x = 8,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeInputPop(0,1,0) end,enabled = true, type = "button",page = "settings_InputPop"},
{id = "Subtract",width = 3,x = 8,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeInputPop(0,-1,0) end,enabled = true, type = "button",page = "settings_InputPop"},
{id = "Add",width = 3,x = 14,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeInputPop(0,0,1) end,enabled = true, type = "button",page = "settings_InputPop"},
{id = "Subtract",width = 3,x = 14,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeInputPop(0,0,-1) end,enabled = true, type = "button",page = "settings_InputPop"},
--OutputPop
{id = "Add",width = 3,x = 2,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputPop(1,0,0,1) end,enabled = true, type = "button",page = "settings_OutputPop"},
{id = "Subtract",width = 3,x = 2,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputPop(-1,0,0,1) end,enabled = true, type = "button",page = "settings_OutputPop"},
{id = "Add",width = 3,x = 8,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputPop(0,1,0,1) end,enabled = true, type = "button",page = "settings_OutputPop"},
{id = "Subtract",width = 3,x = 8,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputPop(0,-1,0,1) end,enabled = true, type = "button",page = "settings_OutputPop"},
{id = "Add",width = 3,x = 14,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputPop(0,0,1,1) end,enabled = true, type = "button",page = "settings_OutputPop"},
{id = "Subtract",width = 3,x = 14,y = 6,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputPop(0,0,-1,1) end,enabled = true, type = "button",page = "settings_OutputPop"},

{id = "Add",width = 3,x = 2,y = 10,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputPop(1,0,0,2) end,enabled = true, type = "button2",page = "settings_OutputPop"},
{id = "Subtract",width = 3,x = 2,y = 14,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputPop(-1,0,0,2) end,enabled = true, type = "button2",page = "settings_OutputPop"},
{id = "Add",width = 3,x = 8,y = 10,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputPop(0,1,0,2) end,enabled = true, type = "button2",page = "settings_OutputPop"},
{id = "Subtract",width = 3,x = 8,y = 14,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputPop(0,-1,0,2) end,enabled = true, type = "button2",page = "settings_OutputPop"},
{id = "Add",width = 3,x = 14,y = 10,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function() ChangeOutputPop(0,0,1,2) end,enabled = true, type = "button2",page = "settings_OutputPop"},
{id = "Subtract",width = 3,x = 14,y = 14,colorOn = colors.yellow,colorOff = colors.gray,charOn = "-",action = function() ChangeOutputPop(0,0,-1,2) end,enabled = true, type = "button2",page = "settings_OutputPop"},

{id = "method",width = 3,x = 1,y = 8,colorOn = colors.yellow,colorOff = colors.gray,charOn = "X",action = function(x) handlePopMethod() end,enabled = true, type = "button",page = "settings_OutputPop"},

--trades
{label = "Trading",id = "t_trade",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Trade",action = function()    goToPage("Trade_Trading") end},
{label = "History",id = "t_history",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Trade",action = function()    goToPage("Trade_History") end},

{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Trade") end,enabled = true, type = "button",page = "Trade_Trading"},
{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Trade") end,enabled = true, type = "button",page = "Trade_History"},
{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Main") end,enabled = true, type = "button",page = "Trade"},
--population
{id = "touristOutput",width = 3,x = -1,y = 2,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function(x) handlePop("touristOutput") end,enabled = false, type = "button",page = "Pop_Settings"},
{id = "autoInput",width = 3,x = -1,y = 3,colorOn = colors.yellow,colorOff = colors.gray,charOn = "+",action = function(x) handlePop("autoInput") end,enabled = false, type = "button",page = "Pop_Settings"},
{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Main") end,enabled = true, type = "button",page = "Pop"},
{id = "Back",width = 3,x = -1,y = 0,colorOn = colors.yellow,colorOff = colors.gray,charOn = "B",action = function() goToPage("Pop") end,enabled = true, type = "button",page = "Pop_Settings"},

{label = "Settings",id = "Settings",x = 5,y = 5,width = 10,height = 3,type = "push",enabled = true,page = "Pop",action = function()    goToPage("Pop_Settings") end},
} 

return ButtonConfig
