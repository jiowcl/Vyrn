# Vyrn  

Vyrn (LuaLiteVM) is a concise and elegant Lua-like programming language written in PureBasic. It draws inspiration from other programming languages ​​and has gradually developed its own unique characteristics. Vyrn is designed for small application development and embedded applications.  

Vyrn is a very young programming language, and not all Lua syntax is available.  

![GitHub](https://img.shields.io/github/license/jiowcl/Vyrn.svg)
![PureBasic](https://img.shields.io/badge/language-PureBasic-blue.svg)

## Environment  

- Windows 11 above (recommend)  
- PureBasic 6.40 above (recommend)  

## How to Build  

Building requires PureBasic Compiler and test under Windows 11.  
Module features require PureBasic 5.20 and above.  

## Example  

Vyrn supports both Lua and Vyrn's own syntax.  

```lua
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
- 2018: Rewritten in `FreeBasic 1.05` using `FBIde`.  
- 2024: Rewritten in the latest version of `PureBasic` and renamed to `Vyrn`.  

## Credits  

- Eros Olmi (BINT32)  
- TJ (luna)  
- airtrack (luna)  

## License  

Copyright (c) 2016-2026 Ji-Feng Tsai.  
Code released under the MIT license.  

## TODO  

- More examples  

## Donation  

If this application help you reduce time to coding, you can give me a cup of coffee :)  

[![paypal](https://www.paypalobjects.com/en_US/TW/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=3RNMD6Q3B495N&source=url)  
[Paypal Me](https://paypal.me/jiowcl?locale.x=zh_TW)  
