# VyrnEmbed  

Hosts load **`Vyrn/Native/Vyrn.dll`** use `Vyrn/Native/include/vyrn.h` (C/C#/C++) or **`Vyrn/Native/include/vyrn.pbi`** (PureBasic).  

## Native DLL (C / C++ / C# / PureBasic)  

**Requirements:** Windows **x64**, PureBasic 6.41 to build the DLL, .NET 8+ for the C# binding.  

Since 1.6.124, ship **`vyrn_miniz.dll`** next to `Vyrn.dll` (or `Vyrn.exe`) — the Windows PB VM loads it at runtime for the `zlib` library.  

`scripts/build_native.ps1` / `pack_release.ps1` copy it. libvyrnrt links miniz statically and does not need the DLL (Linux included).  
