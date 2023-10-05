commands.locate.biome("#forge:is_desert")

a,b,c = commands.data.get.entity("@p")
c= b[1]
d=string.match(c, 'Pos:.-.]')
x,y,z = string.match(d, "(%--%d*%.?%d+).,.(%--%d*%.?%d+).,.(%--%d*%.?%d+)")

for _, row in ipairs(main) do
    print(_,row, " * \t * ")
end

ipairs and pairs