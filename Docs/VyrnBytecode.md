# VyrnBytecode  

Since 1.6.72 Vyrn can compile a .vyrn (or .lua) script into an opaque bytecode file and run it directly.  

Since 1.6.73 the extension is .vyrnc (the 1.6.72 name .vbc is still accepted as a deprecated alias), and the same file runs on both runtimes: the PB VM (CLI, require, IDE, Standalone host) and libvyrnrt (Compile / C stub path).  

The file contains no source text: only the compiled program (instructions, constants, function table, struct metadata and a per-instruction line table).  

Obfuscation, not encryption. The optional XOR layer only hides strings and opcodes from casual inspection (strings, a hex editor). The key stream is derived from data stored in the file itself, so anyone with the Vyrn VM, or who reads this document, can recover the program. Do not put secrets (passwords, API keys) in scripts you ship as .vyrnc.  

## CLI  

| Command | Effect |
|---|---|
| `vyrn --compile-vyrnc app.vyrn -o app.vyrnc` | Compile to an XOR-obfuscated `.vyrnc`. Without `-o`, writes `app.vyrnc` next to the input. It refuses to overwrite the source file. |
| `vyrn --compile-vyrnc app.vyrn -o app.vyrnc --no-obfuscate` | Same container without the XOR layer (flags bit0 = 0). Constants are readable in a hex dump; useful for debugging. |
| `vyrn app.vyrnc` | Run a `.vyrnc` (selected by the extension; `.vbc` also works). |
| `vyrn --run-vyrnc file` | Run a file as bytecode whatever its extension. |
| `vyrn compile app.vyrn -o outdir` | Compile (C stub) ship path; writes `outdir/app.vyrnc` (same VYBX container) for libvyrnrt. |
| `vyrn standalone app.vyrn -o outdir --build-exe` | Standalone package; ships `app.vyrnc` by default (dependencies bundled into `package.preload`). `--ship-source` ships the readable `app.bundle.vyrn` instead. |

Output is deterministic: compiling the same source twice gives identical bytes.  
Header options (`-- vyrn: N strict`, `@bench`, `@unlimited`, timeout, dialect), compile warnings and struct metadata are stored in the file, so a `.vyrnc` run behaves like the source run (warnings are printed again on run).
