print(table.index_of({10, 20, 30}, 20))
print(table.find_index({10, 20, 30}, 20))
print(table.index_of({10, 20, 30}, 99))

local parts = string.split("a,b,c,d", ",", 2)
print(table.concat(parts, "|"))
