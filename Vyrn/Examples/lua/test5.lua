-- ==========================================
-- LUA COMPLEX FUNDAMENTALS EXAMPLE
-- Text-Based Shop & Inventory Simulator
-- ==========================================

-- 1. State Initialization: Player and Store Data
local player = {
    name = "Adventurer",
    gold = 150,
    inventory = {
        { name = "Health Potion", quantity = 2, value = 25 },
        { name = "Iron Sword", quantity = 1, value = 100 }
    }
}

local shopStock = {
    { id = 1, name = "Health Potion", price = 30, stock = 5 },
    { id = 2, name = "Mana Potion", price = 20, stock = 8 },
    { id = 3, name = "Steel Shield", price = 120, stock = 2 },
    { id = 4, name = "Leather Armor", price = 75, stock = 3 }
}

-- 2. Helper Function: Display Player Status and Inventory
local function showPlayerStatus(p)
    print("--------------------------------------------------")
    print(string.format("Player: %s | Gold: %d coins", p.name, p.gold))
    print("Current Inventory:")
    if #p.inventory == 0 then
        print("  (Inventory is empty)")
    else
        for _, item in ipairs(p.inventory) do
            print(string.format("  - %s x%d (Unit Value: %d)", item.name, item.quantity, item.value))
        end
    end
    print("--------------------------------------------------")
end

-- 3. Helper Function: Display Shop Catalog
local function showShopCatalog(shop)
    print("==================================================")
    print("                MERCHANT SHOP CATALOG             ")
    print("==================================================")
    for _, item in ipairs(shop) do
        print(string.format("[%d] %s - Price: %d gold | Stock available: %d", 
            item.id, item.name, item.price, item.stock))
    end
    print("==================================================")
end

-- 4. Transaction Function: Buy Item from Shop
local function buyItem(p, shop, itemId)
    local targetItem = nil
    
    -- Search shop stock for the requested item ID using a loop
    for _, item in ipairs(shop) do
        if item.id == itemId then
            targetItem = item
            break
        end
    end

    -- Validation checks
    if not targetItem then
        print("-> Error: Item ID not found in shop.")
        return
    end

    if targetItem.stock <= 0 then
        print("-> Sorry, " .. targetItem.name .. " is out of stock!")
        return
    end

    if p.gold < targetItem.price then
        print("-> Transaction Failed: Not enough gold to buy " .. targetItem.name .. "!")
        return
    end

    -- Execute Transaction (Deduct gold, reduce stock)
    p.gold = p.gold - targetItem.price
    targetItem.stock = targetItem.stock - 1

    -- Update Player Inventory (Merge stacks if item already exists, otherwise add new entry)
    local foundInInventory = false
    for _, invItem in ipairs(p.inventory) do
        if invItem.name == targetItem.name then
            invItem.quantity = invItem.quantity + 1
            foundInInventory = true
            break
        end
    end

    if not foundInInventory then
        table.insert(p.inventory, { name = targetItem.name, quantity = 1, value = targetItem.price })
    end

    print(string.format("-> Success! You bought 1x %s for %d gold.", targetItem.name, targetItem.price))
end

-- 5. Analytics Function: Calculate Total Player Net Worth
local function calculateNetWorth(p)
    local totalAssetValue = 0
    for _, item in ipairs(p.inventory) do
        totalAssetValue = totalAssetValue + (item.value * item.quantity)
    end
    return p.gold + totalAssetValue
end

-- ==========================================
-- EXECUTION FLOW
-- ==========================================
print("Initializing Shop Simulation...\n")

-- Initial View
showPlayerStatus(player)
showShopCatalog(shopStock)

print("\n[Executing Purchases...]\n")

-- Simulate a valid purchase (Steel Shield)
buyItem(player, shopStock, 3)

print("")

-- Simulate another valid purchase (Health Potion)
buyItem(player, shopStock, 1)

print("")

-- Simulate a failed purchase (Trying to buy Steel Shield again with insufficient gold)
buyItem(player, shopStock, 3)

print("\n")

-- Final Post-Transaction State & Analytics
showPlayerStatus(player)
showShopCatalog(shopStock)

local finalNetWorth = calculateNetWorth(player)
print("--------------------------------------------------")
print(string.format("Final Summary -> Total Estimated Net Worth: %d gold", finalNetWorth))
print("--------------------------------------------------")