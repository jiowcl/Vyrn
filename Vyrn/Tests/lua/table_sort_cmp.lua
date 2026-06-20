-- table.sort with custom comparator

local nums = {3, 1, 4, 1, 5}

table.sort(nums, function(a, b)
  return a > b
end)

print("desc:", table.concat(nums, ","))

local words = {"cherry", "apple", "banana"}

table.sort(words, function(a, b)
  return string.len(a) < string.len(b)
end)

print("by len:", table.concat(words, "|"))
