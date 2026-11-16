--------------------------------------------------------------------------------
-- PROJECT: TACTICAL RPG COMBAT & PARTY SIMULATION ENGINE (LUA FUNDAMENTALS)
-- DESCRIPTION: A robust, multi-system simulation built strictly with core Lua 
--              data structures, control flows, and custom helper algorithms.
--------------------------------------------------------------------------------

-- Seed random generator for procedural combat outcomes
math.randomseed(os.time() or 42)

--------------------------------------------------------------------------------
-- MODULE 1: GAME CONFIGURATION & CONSTANTS
--------------------------------------------------------------------------------
local Config = {
    MAX_ROUNDS = 25,
    DEBUG_MODE = true,
    DIFFICULTY_MULTIPLIER = 1.2,
    CRITICAL_HIT_CHANCE = 0.15,
    CRITICAL_MULTIPLIER = 1.75,
    DODGE_CHANCE = 0.10
}

--------------------------------------------------------------------------------
-- MODULE 2: WORLD & STATE REGISTRY
--------------------------------------------------------------------------------
local GameState = {
    currentRound = 0,
    isGameOver = false,
    victory = false,
    totalDamageDealt = 0,
    totalHealingDone = 0,
    turnsExecuted = 0
}

--------------------------------------------------------------------------------
-- MODULE 3: PARTY AND ENEMY ROSTER DEFINITIONS
--------------------------------------------------------------------------------
local Party = {
    {
        id = "hero_1",
        name = "Sir Valen",
        role = "Paladin",
        level = 5,
        maxHp = 180,
        hp = 180,
        maxMp = 60,
        mp = 60,
        attack = 35,
        defense = 20,
        speed = 12,
        isAlive = true,
        statusEffects = {},
        inventory = { { name = "Health Elixir", count = 3 }, { name = "Mana Potion", count = 2 } }
    },
    {
        id = "hero_2",
        name = "Lyra Swiftarrow",
        role = "Ranger",
        level = 5,
        maxHp = 120,
        hp = 120,
        maxMp = 80,
        mp = 80,
        attack = 42,
        defense = 10,
        speed = 22,
        isAlive = true,
        statusEffects = {},
        inventory = { { name = "Health Elixir", count = 2 } }
    },
    {
        id = "hero_3",
        name = "Ignis the Weaver",
        role = "Mage",
        level = 5,
        maxHp = 95,
        hp = 95,
        maxMp = 150,
        mp = 150,
        attack = 55,
        defense = 6,
        speed = 16,
        isAlive = true,
        statusEffects = {},
        inventory = { { name = "Mana Potion", count = 3 } }
    }
}

local EnemyRoster = {
    {
        id = "enemy_1",
        name = "Goblin Skirmisher",
        role = "Scout",
        level = 4,
        maxHp = 70,
        hp = 70,
        maxMp = 20,
        mp = 20,
        attack = 25,
        defense = 8,
        speed = 25,
        isAlive = true,
        statusEffects = {}
    },
    {
        id = "enemy_2",
        name = "Orc Marauder",
        role = "Warrior",
        level = 6,
        maxHp = 160,
        hp = 160,
        maxMp = 30,
        mp = 30,
        attack = 40,
        defense = 15,
        speed = 10,
        isAlive = true,
        statusEffects = {}
    },
    {
        id = "enemy_3",
        name = "Shadow Sorcerer",
        role = "Caster",
        level = 5,
        maxHp = 90,
        hp = 90,
        maxMp = 120,
        mp = 120,
        attack = 48,
        defense = 7,
        speed = 18,
        isAlive = true,
        statusEffects = {}
    }
}

--------------------------------------------------------------------------------
-- MODULE 4: UTILITY & FORMATTING SUBSYSTEM
--------------------------------------------------------------------------------
local function printLine(char, length)
    char = char or "-"
    length = length or 70
    print(string.rep(char, length))
end

local function logMessage(category, message)
    if Config.DEBUG_MODE then
        print(string.format("[%-8s] %s", string.upper(category), message))
    end
end

--------------------------------------------------------------------------------
-- MODULE 5: STATUS EFFECT SUBSYSTEM
--------------------------------------------------------------------------------
local function applyStatusEffect(target, effectName, duration, potency)
    local exists = false
    for _, effect in ipairs(target.statusEffects) do
        if effect.name == effectName then
            effect.duration = duration -- Refresh duration
            exists = true
            break
        end
    end
    
    if not exists then
        table.insert(target.statusEffects, {
            name = effectName,
            duration = duration,
            potency = potency
        })
        logMessage("STATUS", string.format("%s was afflicted with %s for %d turns!", target.name, effectName, duration))
    end
end

local function processStatusEffects(entity)
    if not entity.isAlive then return end
    
    local remainingEffects = {}
    for _, effect in ipairs(entity.statusEffects) do
        if effect.name == "Burn" then
            local burnDmg = effect.potency
            entity.hp = entity.hp - burnDmg
            if entity.hp < 0 then entity.hp = 0 end
            logMessage("BURN", string.format("%s takes %d fire damage from Burn! (HP: %d/%d)", entity.name, burnDmg, entity.hp, entity.maxHp))
        elseif effect.name == "Regen" then
            local healAmt = effect.potency
            entity.hp = entity.hp + healAmt
            if entity.hp > entity.maxHp then entity.hp = entity.maxHp end
            logMessage("REGEN", string.format("%s recovers %d HP from Regeneration! (HP: %d/%d)", entity.name, healAmt, entity.hp, entity.maxHp))
        end
        
        effect.duration = effect.duration - 1
        if effect.duration > 0 then
            table.insert(remainingEffects, effect)
        else
            logMessage("STATUS", string.format("The %s effect on %s has worn off.", effect.name, entity.name))
        end
    end
    entity.statusEffects = remainingEffects
    
    if entity.hp <= 0 and entity.isAlive then
        entity.isAlive = false
        logMessage("DEATH", string.format("%s succumbed to their status wounds and died!", entity.name))
    end
end

--------------------------------------------------------------------------------
-- MODULE 6: COMBAT ENGINE & INTERACTION SUBSYSTEM
--------------------------------------------------------------------------------
local function calculateDamage(attacker, defender, basePower, isMagic)
    local attackPower = basePower + attacker.attack
    local defensePower = defender.defense
    
    if isMagic then
        defensePower = math.floor(defensePower * 0.5) -- Magic bypasses half armor
    end
    
    local rawDamage = attackPower - defensePower
    if rawDamage < 3 then rawDamage = 3 end
    
    -- Check for dodge
    if math.random() < Config.DODGE_CHANCE then
        logMessage("COMBAT", string.format("%s gracefully dodged the incoming attack from %s!", defender.name, attacker.name))
        return 0, false
    end
    
    -- Check for critical hit
    local isCrit = false
    if math.random() < Config.CRITICAL_HIT_CHANCE then
        rawDamage = math.floor(rawDamage * Config.CRITICAL_MULTIPLIER)
        isCrit = true
    end
    
    -- Small environmental variance
    local variance = math.random(-4, 5)
    local finalDamage = rawDamage + variance
    if finalDamage < 1 then finalDamage = 1 end
    
    return finalDamage, isCrit
end

local function executeAttack(attacker, defender)
    if not attacker.isAlive or not defender.isAlive then return end
    
    print(string.format("-> %s attacks %s with a standard strike!", attacker.name, defender.name))
    local damage, isCrit = calculateDamage(attacker, defender, 10, false)
    
    if damage == 0 then return end
    
    defender.hp = defender.hp - damage
    if defender.hp < 0 then defender.hp = 0 end
    
    GameState.totalDamageDealt = GameState.totalDamageDealt + damage
    
    local critString = isCrit and " **CRITICAL HIT!**" or ""
    print(string.format("   Result: Dealt %d damage to %s.%s (%s HP: %d/%d)", 
        damage, defender.name, critString, defender.name, defender.hp, defender.maxHp))
        
    if defender.hp == 0 then
        defender.isAlive = false
        print(string.format("*** %s has been slain in combat! ***", defender.name))
    end
end

local function executeSkill(attacker, defender, skillName)
    if not attacker.isAlive or not defender.isAlive then return end
    
    if skillName == "Fireball" then
        local cost = 25
        if attacker.mp < cost then
            logMessage("SKILL", string.format("%s tried to cast Fireball, but lacked MP! Defaulting to attack.", attacker.name))
            executeAttack(attacker, defender)
            return
        end
        
        attacker.mp = attacker.mp - cost
        print(string.format("-> %s chants an incantation and hurls a massive Fireball at %s! (Cost: %d MP)", attacker.name, defender.name, cost))
        
        local damage, _ = calculateDamage(attacker, defender, 45, true)
        defender.hp = defender.hp - damage
        if defender.hp < 0 then defender.hp = 0 end
        GameState.totalDamageDealt = GameState.totalDamageDealt + damage
        
        print(string.format("   Result: Inferno deals %d magical damage to %s! (%s HP: %d/%d)", 
            damage, defender.name, defender.name, defender.hp, defender.maxHp))
            
        -- Apply Burn status
        applyStatusEffect(defender, "Burn", 2, 12)
        
        if defender.hp == 0 then
                            defender.isAlive = false
            print(string.format("*** %s was burned to ashes and slain! ***", defender.name))
        end
        
    elseif skillName == "Power Slash" then
        local cost = 15
        if attacker.mp < cost then
            executeAttack(attacker, defender)
            return
        end
        
        attacker.mp = attacker.mp - cost
        print(string.format("-> %s executes a devastating Power Slash against %s! (Cost: %d MP)", attacker.name, defender.name, cost))
        
        local damage, isCrit = calculateDamage(attacker, defender, 30, false)
        damage = math.floor(damage * 1.3) -- Extra skill multiplier
        defender.hp = defender.hp - damage
        if defender.hp < 0 then defender.hp = 0 end
        GameState.totalDamageDealt = GameState.totalDamageDealt + damage
        
        print(string.format("   Result: Slash inflicts %d heavy physical damage to %s! (%s HP: %d/%d)", 
            damage, defender.name, defender.name, defender.hp, defender.maxHp))
            
        if defender.hp == 0 then
            defender.isAlive = false
            print(string.format("*** %s was cleaved in twain and slain! ***", defender.name))
        end
    end
end

local function useConsumable(hero, itemName)
    for _, item in ipairs(hero.inventory) do
        if item.name == itemName and item.count > 0 then
            item.count = item.count - 1
            if itemName == "Health Elixir" then
                local healVal = 60
                hero.hp = hero.hp + healVal
                if hero.hp > hero.maxHp then hero.hp = hero.maxHp end
                GameState.totalHealingDone = GameState.totalHealingDone + healVal
                print(string.format("-> %s consumes a %s, recovering %d HP! (HP: %d/%d)", hero.name, itemName, healVal, hero.hp, hero.maxHp))
                return true
            elseif itemName == "Mana Potion" then
                local mpVal = 50
                hero.mp = hero.mp + mpVal
                if hero.mp > hero.maxMp then hero.mp = hero.maxMp end
                print(string.format("-> %s drinks a %s, restoring %d MP! (MP: %d/%d)", hero.name, itemName, mpVal, hero.mp, hero.maxMp))
                return true
            end
        end
    end
    return false
end

--------------------------------------------------------------------------------
-- MODULE 7: AI & TACTICAL DECISION MAKING SUBSYSTEM
--------------------------------------------------------------------------------
local function selectLivingTarget(targetGroup)
    local livingPool = {}
    for _, member in ipairs(targetGroup) do
        if member.isAlive then
            table.insert(livingPool, member)
        end
    end
    
    if #livingPool == 0 then return nil end
    local index = math.random(1, #livingPool)
    return livingPool[index]
end

local function executeHeroAITurn(hero, enemyList)
    if not hero.isAlive then return end
    print(string.format("\n[Hero Turn] %s (%s) considers their options...", hero.name, hero.role))
    
    -- Tactical Health Check: Use potion if low
    if hero.hp < (hero.maxHp * 0.4) then
        if useConsumable(hero, "Health Elixir") then
            GameState.turnsExecuted = GameState.turnsExecuted + 1
            return
        end
    end
    
    local target = selectLivingTarget(enemyList)
    if not target then return end
    
    -- Role-specific action logic
    if hero.role == "Paladin" then
        if hero.mp >= 15 and math.random() > 0.3 then
            executeSkill(hero, target, "Power Slash")
        else
            executeAttack(hero, target)
        end
    elseif hero.role == "Ranger" then
        executeAttack(hero, target)
    elseif hero.role == "Mage" then
        if hero.mp >= 25 then
            executeSkill(hero, target, "Fireball")
        else
            executeAttack(hero, target)
        end
    else
        executeAttack(hero, target)
    end
    
    GameState.turnsExecuted = GameState.turnsExecuted + 1
end

local function executeEnemyAITurn(enemy, partyList)
    if not enemy.isAlive then return end
    print(string.format("\n[Enemy Turn] %s strikes back!", enemy.name))
    
    local target = selectLivingTarget(partyList)
    if not target then return end
    
    if enemy.role == "Caster" and enemy.mp >= 20 then
        enemy.mp = enemy.mp - 20
        print(string.format("-> %s casts Shadow Bolt on %s!", enemy.name, target.name))
        local damage, _ = calculateDamage(enemy, target, 35, true)
        target.hp = target.hp - damage
        if target.hp < 0 then target.hp = 0 end
        print(string.format("   Result: Shadow Bolt hits for %d damage! (%s HP: %d/%d)", damage, target.name, target.hp, target.maxHp))
        
        if target.hp == 0 then
            target.isAlive = false
            print(string.format("*** Hero %s has fallen in battle! ***", target.name))
        end
    else
        executeAttack(enemy, target)
    end
    
    GameState.turnsExecuted = GameState.turnsExecuted + 1
end

--------------------------------------------------------------------------------
-- MODULE 8: TURN QUEUE & SPEED SORTING SUBSYSTEM
--------------------------------------------------------------------------------
local function compileTurnOrder(party, enemies)
    local masterList = {}
    
    for _, h in ipairs(party) do
        if h.isAlive then table.insert(masterList, h) end
    end
    
    for _, e in ipairs(enemies) do
        if e.isAlive then table.insert(masterList, e) end
    end
    
    -- Sort descending by speed parameter + small random initiative roll
    table.sort(masterList, function(a, b)
        local speedA = a.speed + math.random(1, 10)
        local speedB = b.speed + math.random(1, 10)
        return speedA > speedB
    end)
    
    return masterList
end

--------------------------------------------------------------------------------
-- MODULE 9: GAME STATUS VALIDATION SUBSYSTEM
--------------------------------------------------------------------------------
local function checkBattleConditions(party, enemies)
    local allHeroesDead = true
    for _, h in ipairs(party) do
        if h.isAlive then
            allHeroesDead = false
            break
        end
    end
    
    if allHeroesDead then
        GameState.isGameOver = true
        GameState.victory = false
        return true
    end
    
    local allEnemiesDead = true
    for _, e in ipairs(enemies) do
        if e.isAlive then
            allEnemiesDead = false
            break
        end
    end
    
    if allEnemiesDead then
        GameState.isGameOver = true
        GameState.victory = true
        return true
    end
    
    return false
end

--------------------------------------------------------------------------------
-- MODULE 10: REPORTING & ANALYTICS DASHBOARD
--------------------------------------------------------------------------------
local function printEntityStatusBoard(party, enemies)
    printLine("=", 75)
    print(string.format("               TACTICAL BATTLEFIELD STATUS [ Round: %2d ]          ", GameState.currentRound))
    printLine("-", 75)
    print(" [ HERO PARTY ROSTER ]")
    for _, h in ipairs(party) do
        local statusStr = h.isAlive and string.format("HP: %3d/%3d | MP: %3d/%3d", h.hp, h.maxHp, h.mp, h.maxMp) or "[DEFEATED]"
        print(string.format("   - %-18s (%-7s) -> %s", h.name, h.role, statusStr))
    end
    printLine("-", 75)
    print(" [ ENEMY FORCES ROSTER ]")
    for _, e in ipairs(enemies) do
        local statusStr = e.isAlive and string.format("HP: %3d/%3d | MP: %3d/%3d", e.hp, e.maxHp, e.mp, e.maxMp) or "[DEFEATED]"
        print(string.format("   - %-18s (%-7s) -> %s", e.name, e.role, statusStr))
    end
    printLine("=", 75)
end

local function generatePostActionReport()
    printLine("=", 75)
    print("                    FINAL COMBAT SIMULATION REPORT                     ")
    printLine("=", 75)
    if GameState.victory then
        print(" STATUS: VICTORY! The party successfully triumphed over all hostiles.")
    else
        print(" STATUS: DEFEAT... The party was overwhelmed by enemy forces.")
    end
    print(string.format(" - Total Rounds Completed : %d", GameState.currentRound))
    print(string.format(" - Total Actions Executed : %d", GameState.turnsExecuted))
    print(string.format(" - Cumulative Damage Dealt: %d HP", GameState.totalDamageDealt))
    print(string.format(" - Cumulative Healing Done: %d HP", GameState.totalHealingDone))
    printLine("=", 75)
end

--------------------------------------------------------------------------------
-- MODULE 11: MAIN EXECUTION ORCHESTRATION LOOP
--------------------------------------------------------------------------------
local function runSimulation()
    printLine("=", 75)
    print("           INITIALIZING LUA TACTICAL COMBAT SIMULATOR ENGINE           ")
    printLine("=", 75)
    
    while not GameState.isGameOver and GameState.currentRound < Config.MAX_ROUNDS do
        GameState.currentRound = GameState.currentRound + 1
        
        -- 1. Display Status Board
        printEntityStatusBoard(Party, EnemyRoster)
        
        -- 2. Compile Turn Queue based on speed stats
        local turnQueue = compileTurnOrder(Party, EnemyRoster)
        
        -- 3. Execute Turn Queue Iteration
        for _, entity in ipairs(turnQueue) do
            if entity.isAlive and not GameState.isGameOver then
                -- Process pre-turn status effects (Burn, Regen, etc.)
                processStatusEffects(entity)
                
                if entity.isAlive then
                    -- Check whether entity is a hero or enemy
                    local isEntityHero = false
                    for _, h in ipairs(Party) do
                        if h.id == entity.id then
                            isEntityHero = true
                            break
                        end
                    end
                    
                    if isEntityHero then
                        executeHeroAITurn(entity, EnemyRoster)
                    else
                        executeEnemyAITurn(entity, Party)
                    end
                end
                
                -- Check win/loss conditions dynamically after each individual action
                if checkBattleConditions(Party, EnemyRoster) then
                    break
                end
            end
        end
        
        print("\n") -- Spacing between rounds
    end
    
    -- Final Report Output
    generatePostActionReport()
end

-- Execute the simulation engine
runSimulation()