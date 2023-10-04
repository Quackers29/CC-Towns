local x, y, z = 0,5,0-- specify the coordinates of the block you want to modify
local x1,y1,z1 = -2, 0, -12
--local result, blockInfo = commands.data.get.block(x, y, z, "Label")
local result = true

if result then
    --for _, row in ipairs(blockInfo) do
    --    print(_.." : "..row)
    --end
    commands.clone(x1,y1,z1,x1,y1,z1,x,y,z)
else
    print("Block not found at specified coordinates.")
end

