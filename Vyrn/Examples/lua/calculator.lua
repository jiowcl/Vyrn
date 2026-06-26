-- Vyrn (LuaLiteVM) expression calculator
-- Source from https://github.com/airtrack/luna/blob/master/examples/calculator.lua

global C0
global C9
global C_PLUS
global C_MINUS
global C_MUL
global C_DIV
global C_LPAR
global C_RPAR
global C_SPACE
global C_TAB
global ERR_EXP
global parse_pos

C0 = string.byte('0')
C9 = string.byte('9')
C_PLUS = string.byte('+')
C_MINUS = string.byte('-')
C_MUL = string.byte('*')
C_DIV = string.byte('/')
C_LPAR = string.byte('(')
C_RPAR = string.byte(')')
C_SPACE = string.byte(' ')
C_TAB = string.byte('\t')
ERR_EXP = "error expression"

func is_digit(c)
    return c >= C0 and c <= C9
end

func is_space(c)
    return c == C_SPACE or c == C_TAB
end

func skip_spaces(s, i, len)
    local c = string.byte(s, i)
    while i <= len and is_space(c) do
        i = i + 1
        if i <= len then
            c = string.byte(s, i)
        end
    end
    parse_pos = i
end

func read_number(s, i, len)
    local num = 0
    local c = string.byte(s, i)
    while i <= len and is_digit(c) do
        num = num * 10 + (c - C0)
        i = i + 1
        if i <= len then
            c = string.byte(s, i)
        end
    end
    parse_pos = i
    return num
end

func parse_factor(s, i, len)
    local c
    local num
    local inner
    local neg

    skip_spaces(s, i, len)
    i = parse_pos
    if i > len then
        parse_pos = i
        return ERR_EXP
    end

    neg = 0
    c = string.byte(s, i)
    if c == C_MINUS then
        neg = 1
        i = i + 1
        skip_spaces(s, i, len)
        i = parse_pos
        if i > len then
            parse_pos = i
            return ERR_EXP
        end
        c = string.byte(s, i)
    end

    if c >= C0 then
        if c <= C9 then
            num = read_number(s, i, len)
            if neg == 1 then
                return -num
            else
                return num
            end
        end
    end

    if c == C_LPAR then
        i = i + 1
        inner = parse_expr(s, i, len)
        if inner == ERR_EXP then
            return inner
        end
        i = parse_pos
        skip_spaces(s, i, len)
        i = parse_pos
        if i > len then
            parse_pos = i
            return ERR_EXP
        end
        c = string.byte(s, i)
        if c == C_RPAR then
            parse_pos = i + 1
            if neg == 1 then
                return -inner
            else
                return inner
            end
        else
            parse_pos = i
            return ERR_EXP
        end
    end

    parse_pos = i
    return ERR_EXP
end

func parse_term(s, i, len)
    local result
    local temp
    local c

    result = parse_factor(s, i, len)
    if result == ERR_EXP then
        return result
    end

    while parse_pos <= len do
        i = parse_pos
        skip_spaces(s, i, len)
        i = parse_pos
        if i > len then
            return result
        end
        c = string.byte(s, i)
        if c == C_MUL then
            i = i + 1
            temp = parse_factor(s, i, len)
            if temp == ERR_EXP then
                return temp
            end
            result = result * temp
        elseif c == C_DIV then
            i = i + 1
            temp = parse_factor(s, i, len)
            if temp == ERR_EXP then
                return temp
            end
            result = result / temp
        else
            return result
        end
    end
    return result
end

func parse_expr(s, i, len)
    local result
    local temp
    local c

    result = parse_term(s, i, len)
    if result == ERR_EXP then
        return result
    end

    while parse_pos <= len do
        i = parse_pos
        skip_spaces(s, i, len)
        i = parse_pos
        if i > len then
            return result
        end
        c = string.byte(s, i)
        if c == C_PLUS then
            i = i + 1
            temp = parse_term(s, i, len)
            if temp == ERR_EXP then
                return temp
            end
            result = result + temp
        elseif c == C_MINUS then
            i = i + 1
            temp = parse_term(s, i, len)
            if temp == ERR_EXP then
                return temp
            end
            result = result - temp
        elseif c == C_RPAR then
            return result
        else
            return ERR_EXP
        end
    end
    return result
end

func eval_line(line)
    local len = string.len(line)
    if len == 0 then
        return nil
    end
    local result = parse_expr(line, 1, len)
    skip_spaces(line, parse_pos, len)
    if parse_pos <= len then
        return ERR_EXP
    end
    return result
end

func run_demo()
    print("=== demo mode ===")
    print(eval_line("1+2"))
    print(eval_line("3*4"))
    print(eval_line("(10-3)/2"))
    print(eval_line("2+3*4"))
end

print("Expression calculator (quit or empty line to exit)")

local line = readline("calculator > ")

if line == nil or line == "" then
    run_demo()
else    
    while true do
        if line == "quit" then
            print("bye")
            break
        end
        if line == "exit" then
            print("bye")
            break
        end

        local result = eval_line(line)
        if result == nil then
        else
            print(result)
        end

        line = readline("calculator > ")
        if line == nil then
            print("bye")
            break
        end
        if line == "" then
            print("bye")
            break
        end
    end
end
