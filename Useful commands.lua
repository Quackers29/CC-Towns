Startup commands

pastebin get W5ZkVYSi gitget
gitget Quackers29 CC-Towns main

boolean, tableWithString, distance = commands.locate.biome("#forge:is_desert")
--boolean can be incorrect, search string aswell: if boolean or string.match(tableWithString[1], "(0 blocks away)") then 

a,b,c = commands.data.get.entity("@p")
c= b[1]
d=string.match(c, 'Pos:.-.]')
x,y,z = string.match(d, "(%--%d*%.?%d+).,.(%--%d*%.?%d+).,.(%--%d*%.?%d+)")

for _, row in ipairs(main) do
    print(_,row, " * \t * ")
end

ipairs and pairs

function fileExists(filePath)
    return fs.exists(filePath)
end

local t = {1, 2, 3, 4, 5}
a = math.random(1, #t)
print(a)

time.query.gametime -- day, daytime, could get the time the servers been up and level up in time etc.

experience.query("player", "levels") player levels or points -- tehn set points to use
effect.give("player",effect)
gamerule.comandBlockOutput false
disableRaids
doInsomnia
doTraderSpawning
playersSleepingPercentage
title

https://www.digminecraft.com/game_commands/title_command.php

/title gazer29 title {"text":"The End is Near", "bold":true, "italic":true, "color":"red"}
/title gazer29 subtitle {"text":"Run for your Life!", "italic":true, "color":"yellow"}
/title @a actionbar {"text":"Get Ready!", "color":"light_purple"}
/title @p times 40 120 60
commands.title("gazer29","title","test")

commands.tag("gazer29","add","test")
commands.tag("gazer29","list")
commands.teammsg
commands.team
commands.tell / tellraw
commands.stopsound
commands.scoreboard
commadns.schedule --fucntion
commands.say
commands.playsound
commands.particle
commands.msg
commands.list() -- all commands

commands.xp("add","@a",0) -- will return a list of all online players

os.day()
os.time()
os.clock()

os.date() -- local time
os.date("!%c") -- utc time
os.epoch("utc") -- unix time for timestamping in milliseconds

os.date("%Y-%m-%d %H:%M:%S", os.epoch("utc")/1000)

--Population, % will willing to emigrate (10%)
local boolean,table,count = commands.exec("/kill @e[type=minecraft:villager,x="..PINx..",y="..PINy..",z="..PINz..",distance=..10]")
true, {"Killed Villager"}, 2
commands.summon("minecraft:villager",POUTx,POUTy,POUTz)

local boolean,table,count = commands.exec("/summon minecraft:villager 12 -63 -38 {CustomName:"John",CustomNameVisible:1b}")

commands.summon("minecraft:villager","~","~","~","{\"CustomName\":\"John\",CustomNameVisible:1b}")
"display: {Name:'{\"test\":\"Name Ta\"}'}"
CustomName:'{"text":"Name"}',
CustomName:'{\"text\":\"Name\"}',
CustomName:'{"text":"Pinecastle"}',

commands.summon("minecraft:villager","~","~","~","{CustomName:'{\"text\":\"Pinecastle\"}'}")
commands.exec("/kill @e[type=minecraft:villager,distance=..100] {CustomName:'{\"text\":\"Pinecastle\"}'}")
commands.kill("@e[type=minecraft:villager,distance=..100] {CustomName:'{\"text\":\"Pinecastle\"}'}")

commands.summon("minecraft:villager","~","~","~","{CustomName:'{\"text\":\"Pinecastle\"}'}")
boolean,table,count = commands.kill("@e[type=minecraft:villager,distance=..100,name=!Pinecastle,limit=1]")

commands.exec("/kill @e[type=minecraft:wandering_trader,distance=..100]")
=true,{"killled Wndering Trader"}, 1

trader_llama

/gamerule doTraderSpawning false


fs.getCapacity("") -- outputs cap in bytes for this computer id 
fs.getFreeSpace("") -- gets remaining space in bytes


local data = {
    item = itemString,
    origin = v.folderName,
    distance = v.distance, --transportation distance
    bids = Utility.countDataLines(nearbyResponsesFile), -- gets how many bids there are already
    minPrice = itemdata.minPrice, -- starting bid
    maxPrice = itemdata.maxPrice, -- buy it now
    needed = needed,
    urgencyFactor = possibleBids[itemstring].urgencyFactor,
    quantity = itemdata.count,
    timeOffered = itemdata.timeOffered, -- ID of trade
    timeCloses = itemdata.timeCloses,

    minPrice
    minQuantity
    maxQuantity


    transportCost = math.ceil(offer.distance * transportRate),

    bidPrice = bidPrice,
    buyerTotalCost = bidPrice + offer.transportCost,

    timeResponded = os.epoch("utc"), -- unix time for timestamping, milliseconds
    destination = townFolder,
    timeToDestination = nil,

    timeAccepted = currentTime,
    transportStartTime = currentTime + (PreTransportTimer * 1000)  -- Wait for PreTransportTimer
}






commands.scoreboard.players.get("All", "Restart")
/scoreboard objectives setdisplay sidebar Restart


commands.particle("block_marker", "chest", INx, INy, INz, 0, 0, 0, 0.5, 10, "normal")
commands.particle("end_rod", INx, INy, INz, 0, 0, 0, 0.03, 100, "normal")


commands.exec("/data get block 0 -63 -34000")

commands.setblock(x,-65,z,"air")
"That position is not loaded"


table = commands.getBlockInfo(1,1,1)
table.name == "minecraft:air"
{
    name = name,
}


-- Particles have a 30 metre radius or state "The particle was not visible for anybody"


commands.setblock(1,1,1,"computercraft:computer_command{ComputerId:1,On:1}")
"{facing:north,orientation:north}"



/summon firework_rocket ~ ~1 ~ {LifeTime:20,FireworksItem:{id:"minecraft:firework_rocket",Count:1,tag:{Fireworks:{Explosions:[{Type:4,Flicker:1,Trail:1,Colors:[I;11743532],FadeColors:[I;14602026]}]}}}}
/summon firework_rocket ~ ~1 ~ {LifeTime:20,FireworksItem:{id:"minecraft:firework_rocket",Count:1,tag:{Fireworks:{Explosions:[{Type:4,Flicker:1,Trail:1,Colors:[I;255,65280,11743532],FadeColors:[I;14602026]}]}}}}
commands.exec("summon firework_rocket ~ ~1 ~ {LifeTime:20,FireworksItem:{id:\"minecraft:firework_rocket\",Count:1,tag:{Fireworks:{Explosions:[{Type:4,Flicker:1,Trail:1,Colors:[I;255,65280,11743532],FadeColors:[I;14602026]}]}}}}")

commands.summon("item",x,y,z,"{Item:{id:\"minecraft:emerald\",Count:"..quantity.."},PickupDelay:10}")
/summon item ~ ~ ~ "{Item:{id:\"minecraft:emerald\",Count:1},PickupDelay:10}"


{Profession:librarian}

farmer
librarian
priest
blacksmith
butcher
nitwit
armorer
cartographer

commands.summon("minecraft:villager",1,-57,1,"{CustomName:'{\"text\":\"test1\"}',Profession:Farmer}")

/summon minecraft:villager ~ ~ ~ {VillagerData:{profession:farmer,level:5,type:plains}}

level 2 to 5 works
level 0 and 1 dont 
level 6+ make farmer, no Trade 


armourer: Blast Furnace
butcher: Smoker
cartographer: Cartography Table
cleric: Brewing Stand
farmer: Composter
fisherman: Barrel
fletcher: Fletching Table
leatherworker: Cauldron
librarian: Lectern
masons: Stonecutter
shepherd: Loom
toolsmith: Smithing Table
weaponsmith: Grindstone

{
armourer,
butcher,
cartographer,
cleric,
farmer,
fisherman,
fletcher,
leatherworker,
librarian,
masons,
shepherd,
toolsmith,
weaponsmith
}

commands.summon("minecraft:villager",-38,-57,-70,"{CustomName:'{\"text\":\"test2\"}',VillagerData:{profession:farmer,level:2}}")
{VillagerData:{profession:farmer,level:2}}

NoAI:1 == hovers in mid air

{Silent:1} 

Attributes:[{Name:"generic.movement_speed",Base:0f}]
Attributes:[{Name:\"generic.movement_speed\",Base:0.01}]
commands.summon("minecraft:villager",x,y,z,"{CustomName:'{\"text\":\""..name.."\"}',Attributes:[{Name:\"generic.movement_speed\",Base:0.01}],VillagerData:{profession:"..VilList[math.random(1,#VilList)]..",level:6}}")

/effect give @e[x=X,y=Y,z=Z,distance=..radius] minecraft:potion_effect duration amplifier
/effect clear @e[x=X,y=Y,z=Z,distance=..radius]






max towns

Handle tourists

placement gen, timer difference > 10s dont do anything
2 marker placement
marker within structure for pop out/in

player direction

sales tax



Control PC needs to process unchunk loaded towns..

TRADE UPGRADES RESOURCES PRODUCTION Population

Town PC FOR

UI, ADD RES, ADD POP, INFLUENCE

Purchasable Towns, check if player has a contract in hand after using carrot..



tourist spawn in a line 

EMERALD SHOP CUSTOM


ini files are better for admin settings - can explain 


/forge mods 
outputs list of mods and version numbers so could work



line, multiple checks over line but cannot overlap. easier to go with one radius. 
Add Max length of the output line
Add auto input is output pos


--commands.particle("block_marker", "chest", x, y, z, 0, 0, 0, 0.5, 10, "normal")
--commands.particle("end_rod", x, y, z, 0, 0, 0, 0.03, 100, "normal")
effect  -- potion
entity_effect -- same but multicoloured
sonic_boom -- eyecatch
electric_spark --short
campfire_cosy_smoke -- long
poof


