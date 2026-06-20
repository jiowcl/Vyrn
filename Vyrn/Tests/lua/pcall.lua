local function double(x)
  return x * 2
end

local ok, v = pcall(double, 21)
print("ok", ok, v)

local ok2, err = pcall(function()
  error("boom")
end)
print("fail", ok2, err)

local ok3, r = pcall(function(x)
  return x + 1
end, 41)
print("anon", ok3, r)
