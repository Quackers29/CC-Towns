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
os.date()


local boolean,table,count = commands.exec("/kill @e[type=minecraft:villager,x=12,y=-60,z=-36,distance=..10]")
true, {"Killed Villager"}, 2
commands.summon("minecraft:villager",12,-62,-38)
