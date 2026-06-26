-- anonymous function (LuaLite syntax)

local double = function(x)
  return x * 2
end
print(double(21))

local function apply(f, x)
  return f(x)
end
print(apply(function(x) return x + 1 end, 10))
