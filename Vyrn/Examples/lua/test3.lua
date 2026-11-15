-- ==========================================
-- LUA 5.0 FUNDAMENTALS DEMONSTRATION
-- ==========================================

-- 1. Global vs Local Variables
print("--- 1. Variables and Scope ---")
globalVariable = "I am global"
local localVariable = "I am local to this chunk"

print(globalVariable)
print(localVariable)

-- 2. Basic Control Structures
print("\n--- 2. Control Structures ---")
local score = 85

if score >= 90 then
    print("Grade: A")
elseif score >= 75 then
    print("Grade: B")
else
    print("Grade: C")
end

-- While loop
local count = 3
print("Countdown:")
while count > 0 do
    print(count)
    count = count - 1
end

-- 3. Functions and Closures (Lexical Scoping in Lua 5.0)
print("\n--- 3. Functions and Closures ---")
local function makeCounter()
    local count = 0
    return function()
        count = count + 1
        return count
    end
end

local counterA = makeCounter()
print("Counter A step 1:", counterA())
print("Counter A step 2:", counterA())

-- 4. Tables (Lua's Universal Data Structure)
print("\n--- 4. Tables (Arrays and Dictionaries) ---")

-- Table used as an array (1-indexed)
local colors = {"Red", "Green", "Blue"}
print("First color:", colors[1])

-- Table used as a dictionary / record
local player = {
    name = "Hero",
    health = 100,
    inventory = {"Sword", "Shield"}
}

print("Player Name:", player.name)
print("Player Health:", player.health)
print("First item:", player.inventory[1])

-- 5. Coroutines (Introduced in Lua 5.0)
print("\n--- 5. Coroutines ---")
local co = coroutine.create(function()
    for i = 1, 2 do
        print("Coroutine yielded step:", i)
        coroutine.yield()
    end
    return "completed"
end)

print("Status:", coroutine.status(co))
coroutine.resume(co) -- Runs until first yield
coroutine.resume(co) -- Runs until second yield
local success, result = coroutine.resume(co) -- Finishes execution
print("Final result:", result)