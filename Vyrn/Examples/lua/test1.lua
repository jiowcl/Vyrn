-- ==========================================
-- LUA FUNDAMENTALS DEMONSTRATION
-- ==========================================

-- 1. Variables and Data Types
print("--- 1. Variables & Data Types ---")
local name = "Developer"          -- String
local age = 25                    -- Number (Lua treats all numbers as floats)
local isLearning = true           -- Boolean
local score = nil                 -- Nil (represents absence of value)

print("Name:", name)
print("Age:", age)
print("Is Learning:", isLearning)
print("Score:", score)

-- 2. Basic Arithmetic and Operators
print("\n--- 2. Operators ---")
local a, b = 10, 3
print("a + b =", a + b)
print("a - b =", a - b)
print("a * b =", a * b)
print("a / b =", a / b)
print("a ^ b =", a ^ b)  -- Exponentiation (10 cubed)
print("a % b =", a % b)  -- Modulus (Remainder)

-- 3. Control Structures (Conditions)
print("\n--- 3. Conditions (if-elseif-else) ---")
local temperature = 28

if temperature > 30 then
    print("It's a hot day!")
elseif temperature >= 20 and temperature <= 30 then
    print("The weather is pleasant.")
else
    print("It's a bit cold outside.")
end

-- 4. Loops
print("\n--- 4. Loops ---")

-- Numeric For Loop (from 1 to 3, stepping by 1)
print("Counting with a for loop:")
for i = 1, 3 do
    print("Count:", i)
end

-- While Loop
print("Countdown with a while loop:")
local count = 3
while count > 0 do
    print(count)
    count = count - 1
end
print("Liftoff!")

-- 5. Functions
print("\n--- 5. Functions ---")

-- A function that takes two arguments and returns their sum
local function addNumbers(x, y)
    return x + y
end

local sumResult = addNumbers(15, 25)
print("Sum of 15 and 25 is:", sumResult)

-- 6. Tables (Lua's versatile data structure for arrays and dictionaries)
print("\n--- 6. Tables ---")

-- Used as an Array (1-indexed in Lua!)
local fruits = {"Apple", "Banana", "Cherry"}
print("First fruit:", fruits[1])

-- Adding to an array
table.insert(fruits, "Orange")

-- Iterating through an array using ipairs
print("All fruits:")
for index, fruit in ipairs(fruits) do
    print(index, fruit)
end

-- Used as a Dictionary (Key-Value pairs)
local user = {
    username = "LuaCoder",
    level = 5,
    active = true
}

print("Username:", user.username)
print("Level:", user.level)