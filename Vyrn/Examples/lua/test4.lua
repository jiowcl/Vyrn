-- ==========================================
-- LUA COMPREHENSIVE FUNDAMENTALS EXAMPLE
-- Student Gradebook and Analytics System
-- ==========================================

-- In-memory data storage using nested tables (Arrays and Dictionaries)
local gradebook = {
    { name = "Alice Smith", scores = { math = 88, science = 92, english = 85 } },
    { name = "Bob Jones", scores = { math = 75, science = 68, english = 72 } },
    { name = "Charlie Brown", scores = { math = 95, science = 90, english = 96 } },
    { name = "Diana Prince", scores = { math = 82, science = 85, english = 88 } }
}

-- Helper function: Calculate the average score from a score table
local function calculateAverage(scores)
    local total = 0
    local count = 0
    
    for _, score in pairs(scores) do
        total = total + score
        count = count + 1
    end
    
    if count == 0 then return 0 end
    return total / count
end

-- Helper function: Assign a letter grade based on an average score
local function getLetterGrade(average)
    if average >= 90 then
        return "A"
    elseif average >= 80 then
        return "B"
    elseif average >= 70 then
        return "C"
    elseif average >= 60 then
        return "D"
    else
        return "F"
    end
end

-- Function to add a new student dynamically to the roster
local function addStudent(roster, name, mathScore, scienceScore, englishScore)
    local newStudent = {
        name = name,
        scores = {
            math = mathScore,
            science = scienceScore,
            english = englishScore
        }
    }
    table.insert(roster, newStudent)
    print("-> Successfully added new student: " .. name)
end

-- Function to generate and print a formatted report for all students
local function generateReport(roster)
    print("==================================================")
    print("               CLASS PERFORMANCE REPORT           ")
    print("==================================================")
    
    local classTotalAverage = 0

    for i, student in ipairs(roster) do
        local avg = calculateAverage(student.scores)
        local grade = getLetterGrade(avg)
        classTotalAverage = classTotalAverage + avg

        print(string.format("Student #%d: %s", i, student.name))
        print(string.format("  - Scores -> Math: %d | Science: %d | English: %d", 
            student.scores.math, student.scores.science, student.scores.english))
        print(string.format("  - Average: %.2f | Grade: %s", avg, grade))
        print("--------------------------------------------------")
    end

    local overallClassAvg = classTotalAverage / #roster
    print(string.format("Overall Class Average Score: %.2f", overallClassAvg))
    print("==================================================")
end

-- Function to find and display the top-performing student
local function findTopStudent(roster)
    if #roster == 0 then return end
    
    local topStudent = roster[1]
    local highestAvg = calculateAverage(topStudent.scores)

    for i = 2, #roster do
        local currentAvg = calculateAverage(roster[i].scores)
        if currentAvg > highestAvg then
            highestAvg = currentAvg
            topStudent = roster[i]
        end
    end

    print("\n[Top Performer Highlight]")
    print(string.format("-> %s leads the class with an average score of %.2f!", topStudent.name, highestAvg))
end

-- ==========================================
-- EXECUTION FLOW
-- ==========================================
print("Initializing Gradebook System...\n")

-- 1. Add a new student to the initial list
addStudent(gradebook, "Evan Wright", 91, 89, 94)

print("\n")

-- 2. Process and display the comprehensive report
generateReport(gradebook)

-- 3. Extract the top student using conditional evaluation and loops
findTopStudent(gradebook)