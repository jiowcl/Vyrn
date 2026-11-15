-- =====================================================================
-- LUA ADVANCED FOUNDATIONAL EXAMPLE
-- Text-Based Turn-Based Strategy & Dungeon Combat Simulator
-- =====================================================================

-- Seed random generator for varied battle outcomes
math.randomseed(os.time() or 1)

-- 1. Game State and Entity Definitions
local gameWorld = {
    turnCount = 0,
    maxTurns = 15,
    isGameOver = false,
    victory = false
}

local hero = {
    name = "Sir Arthur",
    class = "Paladin",
    hp = 120,
    maxHp = 120,
    attackPower = 22,
    defense = 12,
    mana = 50,
    maxMana = 50,
    potionsRemaining = 3,
    isDefending = false
}

local enemies = {
    { id = 1, name = "Goblin Scout", hp = 45, maxHp = 45, attack = 15, defense = 4, isAlive = true },
    { id = 2, name = "Orc Brute",   hp = 85, maxHp = 85, attack = 25, defense = 8, isAlive = true },
    { id = 3, name = "Dark Wizard", hp = 50, maxHp = 50, attack = 30, defense = 2, isAlive = true }
}

-- 2. Utility / Helper Functions
local function printSeparator(char, length)
    char = char or "-"
    length = length or 60
    print(string.rep(char, length))
end

local function showBattleStatus(h, enemyList)
    print(string.format(" STATUS REPORT [ Turn: %d ]", gameWorld.turnCount))
    print(string.format(" HERO: %s (%s) | HP: %d/%d | Mana: %d/%d | Potions: %d", 
        h.name, h.class, h.hp, h.maxHp, h.mana, h.maxMana, h.potionsRemaining))
    print(" ENEMIES IN COMBAT:")
    for _, e in ipairs(enemyList) do
        if e.isAlive then
            print(string.format("   [%d] %s -> HP: %d/%d | ATK: %d | DEF: %d", 
                e.id, e.name, e.hp, e.maxHp, e.attack, e.defense))
        else
            print(string.format("   [X] %s -> [DEFEATED]", e.name))
        end
    end
end

local function checkVictoryOrDefeat(h, enemyList)
    -- Check if Hero died
    if h.hp <= 0 then
        gameWorld.isGameOver = true
        gameWorld.victory = false
        return true
    end

    -- Check if all enemies are defeated
    local allEnemiesDead = true
    for _, e in ipairs(enemyList) do
        if e.isAlive then
            allEnemiesDead = false
            break
        end
    end

    if allEnemiesDead then
        gameWorld.isGameOver = true
        gameWorld.victory = true
        return true
    end

    return false
end

-- 3. Combat Action Subsystems
local function heroBasicAttack(h, target)
    print(string.format("-> %s swings his sword at %s!", h.name, target.name))
    -- Damage formula: max(1, Attack - target Defense) + small random variance
    local baseDamage = h.attackPower - target.defense
    if baseDamage < 3 then baseDamage = 3 end
    local variance = math.random(-3, 4)
    local finalDamage = baseDamage + variance
    if finalDamage < 1 then finalDamage = 1 end

    target.hp = target.hp - finalDamage
    if target.hp < 0 then target.hp = 0 end

    print(string.format("   Result: Dealt %d physical damage to %s! (%s HP remaining: %d/%d)", 
        finalDamage, target.name, target.name, target.hp, target.maxHp))

    if target.hp == 0 then
        target.isAlive = false
        print(string.format("*** %s has been slain! ***", target.name))
    end
end

local function heroCastSpell(h, target)
    local spellCost = 15
    if h.mana < spellCost then
        print("-> Not enough mana to cast Holy Smite! Defaulting to a standard attack.")
        heroBasicAttack(h, target)
        return
    end

    h.mana = h.mana - spellCost
    print(string.format("-> %s chants a prayer and unleashes Holy Smite on %s! (Mana cost: %d)", 
        h.name, target.name, spellCost))

    -- Magic ignores a portion of defense
    local spellDamage = 35 - math.floor(target.defense / 2)
    if spellDamage < 10 then spellDamage = 10 end

    target.hp = target.hp - spellDamage
    if target.hp < 0 then target.hp = 0 end

    print(string.format("   Result: Holy fire erupts for %d magical damage! (%s HP remaining: %d/%d)", 
        spellDamage, target.name, target.hp, target.maxHp))

    if target.hp == 0 then
        target.isAlive = false
        print(string.format("*** %s has been purified and slain! ***", target.name))
    end
end

local function heroDrinkPotion(h)
    if h.potionsRemaining <= 0 then
        print("-> You reach into your pouch, but you are out of healing potions!")
        return false
    end

    local healAmount = 50
    h.potionsRemaining = h.potionsRemaining - 1
    h.hp = h.hp + healAmount
    if h.hp > h.maxHp then 
        h.hp = h.maxHp 
    end

    print(string.format("-> %s drinks a glowing health potion, recovering %d HP! (HP: %d/%d, Potions left: %d)", 
        h.name, healAmount, h.hp, h.maxHp, h.potionsRemaining))
    return true
end

local function enemyTurnAI(h, enemyList)
    print("\n--- Enemy Phase ---")
    for _, e in ipairs(enemyList) do
        if e.isAlive and not gameWorld.isGameOver then
            -- Simple AI logic: Choose action based on current health percentage
            local healthPercent = e.hp / e.maxHp
            
            if healthPercent < 0.25 and math.random() > 0.5 then
                -- Defensive posture / evasion recovery attempt
                print(string.format("-> %s braces itself defensively, sensing danger!", e.name))
            else
                -- Offensive attack calculation
                print(string.format("-> %s attacks %s!", e.name, h.name))
                
                local effectiveDefense = h.defense
                if h.isDefending then
                    effectiveDefense = effectiveDefense * 2
                    print(string.format("   (%s's defensive stance dampens the blow!)", h.name))
                end

                local rawDmg = e.attack - math.floor(effectiveDefense / 2)
                if rawDmg < 2 then rawDmg = 2 end
                local dmgVariance = math.random(-2, 3)
                local finalDmg = rawDmg + dmgVariance
                if finalDmg < 1 then finalDmg = 1 end

                h.hp = h.hp - finalDmg
                if h.hp < 0 then h.hp = 0 end

                print(string.format("   Result: %s takes %d damage! (Hero HP: %d/%d)", 
                    h.name, finalDmg, h.hp, h.maxHp))
            end
        end
    end
end

-- 4. Simulated Interactive Game Loop (Automated script demonstration)
-- In a real console environment, this would read user input via io.read()
local function simulatePlayerChoice(turnIndex, h, enemyList)
    print(string.format("\n--- Hero Turn #%d ---", turnIndex))
    h.isDefending = false -- Reset defense stance from previous turn

    -- Find the first available living target to attack
    local target = nil
    for _, e in ipairs(enemyList) do
        if e.isAlive then
            target = e
            break
        end
    end

    if not target then return end

    -- Scripted tactical decision tree based on turn progression
    if h.hp < 50 and h.potionsRemaining > 0 then
        heroDrinkPotion(h)
    elseif h.mana >= 15 and turnIndex % 2 == 1 then
        heroCastSpell(h, target)
    else
        heroBasicAttack(h, target)
    end
end

-- =====================================================================
-- MAIN EXECUTION SIMULATION FLOW
-- =====================================================================
print("Dungeon Encounter Started: Ambush in the Crypts!\n")

while not gameWorld.isGameOver and gameWorld.turnCount < gameWorld.maxTurns do
    gameWorld.turnCount = gameWorld.turnCount + 1

    -- 1. Display Current Combat Board
    showBattleStatus(hero, enemies)

    -- 2. Hero's Turn
    simulatePlayerChoice(gameWorld.turnCount, hero, enemies)

    -- Check win condition immediately after hero attack
    if checkVictoryOrDefeat(hero, enemies) then
        break
    end

    -- 3. Enemies' Turn
    enemyTurnAI(hero, enemies)

    -- Check defeat condition after enemy counter-attacks
    if checkVictoryOrDefeat(hero, enemies) then
        break
    end

    print("\n")
end

-- =====================================================================
-- POST-BATTLE SUMMARY REPORT
-- =====================================================================
printSeparator("=", 65)
print("                    BATTLE SIMULATION CONCLUDED                    ")
printSeparator("=", 65)

if gameWorld.victory then
    print(string.format(" VICTORY! %s successfully triumphed over the dungeon threat!", hero.name))
    print(string.format(" Remaining Hero Health: %d/%d HP", hero.hp, hero.maxHp))
    print(string.format(" Total Turns Taken: %d", gameWorld.turnCount))
else
    print(string.format(" DEFEAT... %s fell in battle after %d grueling turns.", hero.name, gameWorld.turnCount))
    print(" The dungeon claims another soul...")
end

printSeparator("=", 65)