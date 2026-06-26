local function fact(n)
  if n <= 1 then
    return 1
  end
  return n * fact(n - 1)
end
print("fact", fact(5))

local function make_adder(n)
  local function add(x)
    return x + n
  end
  return add
end
print("adder", make_adder(10)(7))

function counter_test()
  local count = 0
  local function tick()
    count = count + 1
    return count
  end
  print("tick", tick(), tick(), tick())
end
counter_test()
