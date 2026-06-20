-- table.sort is stable: equal keys keep their relative order
local words = {"cherry", "banana", "apple", "date"}

table.sort(words, function(a, b)
  return string.len(a) < string.len(b)
end)

print(table.concat(words, "|"))
