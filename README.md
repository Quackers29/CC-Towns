# CC-Towns
![2023-10-11_19 57 38](https://github.com/Quackers29/CC-Towns/assets/11053436/10cdbb2f-fdda-4f29-a7a4-6d07c8116f14)


# Current State
  View the Wiki for an overview of the project and it's current features
  https://github.com/Quackers29/CC-Towns/wiki

# Installation instructions

Server settings: command block use to true, command block output to false

Place down a command computer, only accessable through /give command

On the command computer, edit a file and save it so it creates a folder

In this new folder locate the github repo clone

Add a chest to the West side of the computer and another two blocks higher

Add a monitor to the setup

Restart the computer

Duplicate this computer with the same id to create more towns.



{
  "main": {
    "packages": { --enable specific packages of the project
      "tourist": true,
      "population": false, -- unused
      "production": true,
      "resources": true,
      "upgrades": true,
      "trade": false, can be used
      "generation": false -- experimental use with caution 
    },
    "version": 1, -- version number alter to adapt the code to different versions of mc
    "timeZone": 0, -- timezone hours to add to utc can be negative 
    "controlMethod": "all",
    "controlPC": { --town computers placed here will not create a town and can be used for admin purposes 
      "x": 0,
      "z": -0,
      "autoUpdate": false
    }
  },
  "town": {
    "startup": false, -- unused
    "minDistance": 8, -- 
    "restart": 0, -- unused
    "adminWait": 10, -- time in seconds a town will check the admin loop which includes restart commands
    "maxSpawnRange": 50, -- max range a town can spawn entities 
    "maxVillagerOut": 20, --
    "maxLineLength": 20, -- max range a town has between to spawn ends
    "maxChestRange": 20, -- max range a town chest can be placed
    "villagerSpacing": 1, -- entity spawn spacing radius in meters 1 default 0.7 safe minimum
    "gridSpacing": true, -- if entities spawn in the centre of blocks
    "mainWait": 10, -- time in seconds the town will loop  main processes including tourists
    "chestRefresh": 5, -- time in seconds the town will check input output chests
    "monitorRefresh": 1 -- time in seconds the town will update monitor pages where needed like the map
  },
  "generation": {
    "State": true,
    "Type": 0,
    "minDistance": 10,
    "maxDistance": 12,
    "spread": 45,
    "monitorBuild": true, -- enables monitor building and removal around the new town computer
    "monitorOut": 2, -- monitor blocks wide the new town will have excluding the centre 
    "monitorHigh": 3, -- monitor blocks high the new town will have
    "biomeCheck": false --checks which biome from the biome list the town is in on creation
  },
  "tourist": {
    "genCostEnabled": false, --enable genCosts removed from the town per tourist generated
    "genCosts": { --cost per tourist
      "minecraft:bread": 50
    },
    "genTime": 30, --base generation time per tourist in seconds
    "genCap": 10, --max tourists in the town
    "maxOut": 5, --max tourists out per town
    "textColor": "yellow", --colour of tourist name
    "dropReward": false, --drop the items at the tourist input location or store in the town
    "payEnabled": true, --enable payment from tourists
    "payMinDist": 50, --minimum distance tourist must travel before paying
    "payDistPerItem": 10, --tourists pay distance per payment item
    "payItem": "minecraft:emerald", --item used for tourists to pay for trip
    "milestonesEnabled": true, --enable milestones
    "milestones": {
      "50": [{ "item": "minecraft:cooked_beef", "quantity": 1 }],
      "100": [
        { "item": "minecraft:nether_star", "quantity": 1, "weight": 1 },
        { "item": "minecraft:torch", "quantity": 1, "weight": 1 },
        { "item": "minecraft:emerald", "quantity": 10, "weight": 20 },
        { "item": "minecraft:cooked_beef", "quantity": 20, "weight": 70 },
        { "item": "minecraft:experience_bottle", "quantity": 10, "weight": 50 }
      ]
    }
  },
  "population": {
    "generationCost": true,
    "upkeep": false
  }
}


