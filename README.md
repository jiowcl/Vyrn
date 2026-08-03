# Vyrn  

**Tiny, Elegant, and Fast — A Modern Lua-inspired Programming Language Implemented in PureBasic.**  

**Vyrn** is a concise, lightweight programming language designed for small-scale applications and embedded scripting. Built entirely in **PureBasic**, it brings the familiar elegance of **Lua** while evolving its own unique language characteristics.  

![GitHub](https://img.shields.io/github/license/jiowcl/Vyrn.svg)
![PureBasic](https://img.shields.io/badge/language-PureBasic-blue.svg)
![Status](https://img.shields.io/badge/Status-Experimental-orange)

## Features  

- **Ultra Lightweight**: Minimal footprint with zero extra dynamic libraries needed.  
- **Pure $PureBasic Implementation**: Seamlessly embeddable into host applications written in PureBasic or C.  
- **Lua-Inspired Syntax**: Familiar, clean, and quick to learn for Lua developers.  
- **Built for Embedding**: Designed specifically for scriptable apps, game engine logic, and small tooling.  
- **Syntax Highlighting IDE**: Designed specifically for Vyrn's unique grammar and built-in functions.  

## Environment  

- Windows 11 above (recommend)  
- PureBasic 6.40 above (recommend)  

## How to Build  

Building requires PureBasic Compiler and test under Windows 11.  
Module features require PureBasic 5.20 and above.  

## Example  

Vyrn supports both Lua and Vyrn's own syntax.  

```vyrn
-- Vyrn (Optional Typing)
def greet(name: string) -> string
    return "Hello, " .. name .. "!"
end

def calculate_bonus(score: number) -> number
    return score * 1.1
end

print(greet("Vyrn"))
print(calculate_bonus(100))

-- Output:
-- Hello, Vyrn!
-- 110
```

```lua
-- Lua
function greet(name)
    return "Hello, " .. name .. "!"
end

function calculate_bonus(score)
    return score * 1.1
end

print(greet("Vyrn"))
print(calculate_bonus(100))

-- Output:
-- Hello, Vyrn!
-- 110
```

## History  

- 2016: Vyrn (LuaLiteVM) was initially written in `PowerBasic 10.04`.  
- 2018: Rewritten in `FreeBasic 1.05` using `FBEdit`.  
- 2024: Rewritten in the latest version of `PureBasic` and renamed to `Vyrn`.  

## Credits  

- Eros Olmi (BINT32)  
- TJ (luna)  
- airtrack (luna)  

## License  

Copyright (c) 2016-2026 Ji-Feng Tsai.  
Code released under the MIT license.  

## TODO  

- Built-in Functions (IO, File, Socket, etc)  
- Compile-time Strict  
- Error Handling  
- More examples  

## Donation  

If this application help you reduce time to coding, you can give me a cup of coffee :)  

[![paypal](https://www.paypalobjects.com/en_US/TW/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=3RNMD6Q3B495N&source=url)  

[Paypal Me](https://paypal.me/jiowcl?locale.x=zh_TW)  
