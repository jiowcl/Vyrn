-- ==========================================
-- LUA FUNDAMENTALS - PART 2: ADVANCED CONCEPTS
-- ==========================================

-- 1. Closures and First-Class Functions
print("--- 1. Closures & Factory Functions ---")
local function createCounter(startValue)
    local count = startValue or 0
    return function()
        count = count + 1
        return count
    end
end

local counterA = createCounter(10)
print("Counter A:", counterA()) -- 11
print("Counter A:", counterA()) -- 12

-- 2. Varargs (Variable Number of Arguments)
print("\n--- 2. Varargs (...) ---")
local function sumAll(...)
    local total = 0
    -- The table {...} packs the arguments
    for _, v in ipairs({...}) do
        total = total + v
    end
    return total
end

print("Sum of 5, 10, 15, 20:", sumAll(5, 10, 15, 20))

-- 3. Multiple Return Values
print("\n--- 3. Multiple Return Values ---")
local function getMinMax(tbl)
    local min, max = tbl[1], tbl[1]
    for _, v in ipairs(tbl) do
        if v < min then min = v end
        if v > max then max = v end
    end
    return min, max
end

local numbers = {42, 12, 89, 5, 67}
local lowest, highest = getMinMax(numbers)
print("Lowest:", lowest, "| Highest:", highest)

-- 4. Metatables and Metamethods (OOP-like behavior)
print("\n--- 4. Metatables & Object Orientation ---")
local Vector = {}
Vector.__index = Vector

-- Constructor function
function Vector.new(x, y)
    local self = setmetatable({}, Vector)
    self.x = x
    self.y = y
    return self
end

-- Defining a metamethod for table addition (+)
function Vector.__add(v1, v2)
    return Vector.new(v1.x + v2.x, v1.y + v2.y)
end

-- Custom string representation metamethod
function Vector.__tostring(v)
    string.format("Vector(%d, %d)", v.x, v.y)
    return "(" .. v.x .. ", " .. v.y .. ")"
end

local v1 = Vector.new(2, 3)
local v2 = Vector.new(5, 7)
local v3 = v1 + v2 -- Uses the __add metamethod!

print("Vector 1:", v1)
print("Vector 2:", v2)
print("Sum Vector (v1 + v2):", v3)

-- 5. Error Handling (pcall - Protected Call)
print("\n--- 5. Safe Error Handling ---")
local function riskyOperation(shouldFail)
    if shouldFail then
        error("Something went catastrophically wrong!")
    end
    return "Success!"
end

-- pcall runs a function in protected mode
local success, result = pcall(riskyOperation, true)

if success then
    print("Result:", result)
else
    print("Caught an error safely:", result)
end