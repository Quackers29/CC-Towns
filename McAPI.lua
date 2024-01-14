local McAPI = {}
local McVersion = 0 -- initialise to set version

--Initialises the apis Minecraft version number to alternate some commands
function McAPI.Init(version)
    McVersion = version
end

-- Gets the Villager Count within a radius with the name not Villager
function McAPI.GetVillagerCount(x,y,z, radius)
    local boolean,message,count = commands.exec("/effect give @e[name=!Villager,type=minecraft:villager,x="..x..",y="..y..",z="..z..",distance=.."..radius.."] minecraft:slowness 1")
    commands.exec("/effect clear @e[name=!Villager,type=minecraft:villager,x="..x..",y="..y..",z="..z..",distance=.."..radius.."]")
    return count
end

-- Sends a firework from a relative position with a type
function McAPI.SummonFirework(x,y,z, type)
    commands.exec("summon firework_rocket ~"..x.." ~"..y.." ~"..z.." {LifeTime:20,FireworksItem:{id:\"minecraft:firework_rocket\",Count:1,tag:{Fireworks:{Explosions:[{Type:"..type..",Flicker:1,Trail:1,Colors:[I;255,65280,11743532],FadeColors:[I;14602026]}]}}}}")
end

-- Main function to fill an area with optionally oriented blocks
function McAPI.fillArea(startX, startY, startZ, endX, endY, endZ, blockName)
    for x = startX, endX do
        for y = startY, endY do
            for z = startZ, endZ do
                McAPI.setBlock(x, y, z, blockName)
            end
        end
    end
end
-- Example usage
-- Replace these values with your specific coordinates and desired block
-- Orientation is optional; remove or leave it empty for default orientation
-- Utility.fillArea(10, 64, 10, 12, 66, 12, "computercraft:monitor_advanced{width:1}", "facing=north")

-- Function to execute the setblock command
function McAPI.setBlock(x, y, z, blockName)
    local command = "setblock " .. x .. " " .. y .. " " .. z .. " " .. blockName
    commands.exec(command)
end

-- Function to execute the setblock command with optional orientation if not air
function McAPI.SetBlockSafe(x,y,z, block, facing)
    if McAPI.isAirBlock(x, y, z) then
        if facing == nil or facing == "" then
            McAPI.setBlock(x,y,z, block)
        else
            McAPI.setBlock(x,y,z, block.."[facing="..facing.."]")
        end
    end
end

-- Function to check if the chunk at (x, z) is loaded
-- Return true if loaded, false otherwise
function McAPI.isChunkLoaded(x, z)
    local boolean,table,count = commands.setblock(x,-65,z,"air")
    print(table[1], x, z)
    if table[1] == "That position is out of this world!" then --"That position is out of this world!"
        return true
    end
    return false
end

-- Checks if the block at (x, y, z) is air
function McAPI.isAirBlock(x, y, z)
    local table = commands.getBlockInfo(x,y,z)
    if table and table.name == "minecraft:air" then
        return true
    end
    return false
end

-- Checks is the required space above the y level is air block
function McAPI.isSpaceAboveClear(x, groundY, z, requiredSpace)
    for y = groundY + 1, groundY + requiredSpace do
        if not McAPI.isAirBlock(x, y, z) then
            return false  -- Return false if a non-air block is found
        end
    end
    return true  -- Return true if all checked blocks are air
end

-- Finds the ground level (not air) from the start y to the min y, returns nil if ground not found
function McAPI.findGroundLevel(x, startY, z, minY)
    for y = startY, minY, -1 do
        if not McAPI.isAirBlock(x, y, z) then
            return y  -- Return the Y-coordinate of the ground level
        end
    end
    return nil  -- Return nil if no ground is found (e.g., over a void or an unusual world)
end


-- Gets the scoreboard of a player on an objective, returns 0 if none found, handles unset objective
function McAPI.ScoreGet(player, objective)
    local result, tableWithString, score = commands.scoreboard.players.get(player, objective)
    if string.match(tableWithString[1], "Can't get value") then
        --No score set  
        return 0
    elseif string.match(tableWithString[1], "Unknown scoreboard objective") then
        --No objective set
        McAPI.ScoreObjSet(objective)
        return 0
    else
        return score
    end
end

-- Sets the scoreboard of a player on an objective, handles unset objective
function McAPI.ScoreSet(player, objective, score)
    local boolean, tableWithString, value = commands.scoreboard.players.set(player, objective, score)
    if string.match(tableWithString[1], "Unknown scoreboard objective") then
        McAPI.ScoreObjSet(objective)
        commands.scoreboard.players.set(player, objective, score)
    end
end

function McAPI.ScoreObjSet(objective)
    commands.scoreboard.objectives.add(objective, "dummy")
end

-- Summons items at the coordinates
function McAPI.SummonItem(x,y,z,item,count)
    commands.summon("item",x,y,z,"{Item:{id:\""..item.."\",Count:"..count.."},PickupDelay:10}")
end

-- Says a global message
function McAPI.Say(text)
    commands.say(text)
end

-- Say a message in a radius of a position, optional color (default green)
function McAPI.SayNear(text,x,y,z,radius,color)
    if color == nil or color == "" then
        color = "green"
    end
    commands.exec("/execute as @a[x="..x..",y="..y..",z="..z..",distance=.."..radius.."] run tellraw @s {\"text\":\""..text.."\",\"color\":\""..color.."\"}")
end

-- Summons a custom Villager, profession can be set to random
function McAPI.SummonCustomVill(x,y,z,name, profession)
    if profession and profession == "random" then
        local VilList = {
            "armourer","butcher","cartographer","cleric","farmer",
            "fisherman","fletcher","leatherworker","librarian",
            "masons","shepherd","toolsmith","weaponsmith"
            }
        commands.summon("minecraft:villager",x,y,z,"{CustomName:'{\"text\":\""..name.."\"}',Attributes:[{Name:\"generic.movement_speed\",Base:0.01}],VillagerData:{profession:"..VilList[math.random(1,#VilList)]..",level:6}}")
    elseif profession and profession ~= "" then
        commands.summon("minecraft:villager",x,y,z,"{CustomName:'{\"text\":\""..name.."\"}',Attributes:[{Name:\"generic.movement_speed\",Base:0.01}],VillagerData:{profession:"..profession..",level:6}}")
    else
        commands.summon("minecraft:villager",x,y,z,"{CustomName:'{\"text\":\""..name.."\"}',Attributes:[{Name:\"generic.movement_speed\",Base:0.01}]}")
    end
end

-- Kills a custom villager with an optional notname
function McAPI.KillCustomVill(x,y,z,range,notName)
    local test1 = "@e[type=minecraft:villager,x="..tostring(x)..",y="..tostring(y)..",z="..tostring(z)..",distance=.."..range..",name=!Villager,name=!'"..notName.."',limit=1]"
    local boolean,table,count = commands.kill(test1)
    local result = string.match(table[1], "Killed (.+)")
    return result
end

-- returns the biome, alternates commands based on initialised McVersion number
function McAPI.LocateBiome(biome)
    local boolean, tableWithString, distance = nil,nil,nil
    if McVersion == 1 then
        boolean, tableWithString, distance = commands.locate.biome(biome)
    else
        boolean, tableWithString, distance = commands.locatebiome(biome)
    end
    return boolean, tableWithString, distance
end

-- Checks facing of block, returns nil otherwise
function McAPI.GetFacing(x, y, z)
    local table = commands.getBlockInfo(x,y,z)
    if table and table.state.facing ~= nil then
        return table.state.facing
    end
    return nil
end

-- Checks ComputerId, returns nil otherwise
function McAPI.GetComputerId(x, y, z)
    local table = commands.getBlockInfo(x,y,z)
    if table and table.nbt.ComputerId ~= nil then
        return table.nbt.ComputerId
    end
    return nil
end

-- Creates particle effect
--/particle <name> <x> <y> <z> <xd> <yd> <zd> <speed> [count] [mode] [player]
function McAPI.Particle(particle,x,y,z, speed, count, ...)
    if select(1,...) then
        commands.particle(particle, select(1,...), x, y, z, 0, 0, 0,speed, count, "normal")
    else
        commands.particle("end_rod", x, y, z, 0, 0, 0,speed, count, "normal")
    end
end

return McAPI