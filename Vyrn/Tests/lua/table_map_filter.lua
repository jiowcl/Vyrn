local doubled = table.map({1, 2, 3}, function(k, v)
  return v * 2
end)
print(table.concat(doubled, ","))

local evens = table.filter({a = 1, b = 2, c = 3, d = 4}, function(k, v)
  return v % 2 == 0
end)

local keys = ""
table.foreach(evens, function(k, v)
  keys = keys .. k
end)
print(keys)
