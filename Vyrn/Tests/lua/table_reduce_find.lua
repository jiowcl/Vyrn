local sum = table.reduce({1, 2, 3, 4}, 0, function(acc, k, v)
  return acc + v
end)
print("sum", sum)

local k, v = table.find({a = 1, b = 5, c = 3}, function(key, val)
  return val > 3
end)
print("found", k, v)

local k2, v2 = table.find({1, 2}, function(key, val)
  return val > 10
end)
print("miss", k2, v2)
