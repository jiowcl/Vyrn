-- nested functions capture outer locals

func outer()
  local x = 10
  local function inner()
    print(x)
  end
  inner()
end
outer()

func make()
  local n = 5
  local function get()
    return n
  end
  return get
end

local g = make()
print(g())
