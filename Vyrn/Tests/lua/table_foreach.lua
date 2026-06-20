local sum = 0
table.foreach({a = 10, b = 20, c = 5}, function(k, v)
  sum = sum + v
end)
print("sum", sum)

local stopped = table.foreach({1, 2, 3, 4}, function(k, v)
  if v >= 3 then
    return "halt at " .. v
  end
end)
print(stopped)
