assert(true)
assert(42)
print(assert(7))

local ok, err = pcall(function()
  assert(false, "nope")
end)
print(ok, err)
