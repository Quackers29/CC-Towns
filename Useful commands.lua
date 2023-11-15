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
    imeCloses = itemdata.timeCloses,

    transportCost = math.ceil(offer.distance * transportRate),

    bidPrice = bidPrice,
    buyerTotalCost = bidPrice + offer.transportCost,

    timeResponded = os.epoch("utc"), -- unix time for timestamping, milliseconds
    destination = townFolder,
    timeToDestination = nil,

    timeAccepted = currentTime,
    transportStartTime = currentTime + (PreTransportTimer * 1000)  -- Wait for PreTransportTimer
}