# Vyrn IDE extensions

Optional `*.ps1` scripts in this folder appear under **Tools → Automation → Extensions**.

## How scripts run

| Item | Behavior |
|------|----------|
| **Host** | `powershell.exe -NoProfile -ExecutionPolicy Bypass -File <script>` |
| **Working directory** | Repository root when `scripts\ship_standalone.ps1` is found; otherwise the IDE directory |
| **Output** | stdout/stderr lines are appended to the IDE **output** pane |
| **Exit code** | Non-zero exit prints `[error] extension exit <code>`; zero sets status "Extension finished" |
| **Menu** | Up to 8 scripts (`#Ide_ExtMax`); **Tools → Refresh extensions** rescans |

## Environment variables

Set immediately before the process starts (see `Ide_Dev_SetExtensionEnv`):

| Variable | Value |
|----------|--------|
| `VYRN_IDE_FILE` | Active editor path, or empty for untitled buffers |
| `VYRN_IDE_ROOT` | Repo root when known; else IDE install directory |
| `VYRN_DLL` | Loaded `Vyrn.dll` path when the runtime is ready |
| `VYRN_IDE_RUN_OK` | `1` after F5 if the run succeeded (hook only) |
| `VYRN_IDE_RUN_EXIT` | `1` after F5 if the run failed (hook only) |
| `VYRN_IDE_CHECK_OK` | `1` after F8 syntax check passes (check hook only) |
| `VYRN_IDE_SHIP_OK` | `1` after a **Ship** job succeeds (ship hook only) |

## Auto hooks

| Script | When |
|--------|------|
| **`on_run_finish.ps1`** | After every **F5** completes (success or failure) |
| **`on_check_finish.ps1`** | After **F8** syntax check job completes |
| **`on_ship_finish.ps1`** | After **Ship** menu jobs complete |

Copy from `on_run_finish.ps1.example` / `on_check_finish.ps1.example` / `on_ship_finish.ps1.example` and rename (hooks are opt-in). Keep runs fast and non-interactive.

Custom **Automation** entries from `ide/tools.ini` (or copy `tools.ini.example` beside `VyrnIDE.exe`; tokens `{file}` / `{dir}`) use the same env (not PowerShell-only).

## Authoring guidelines

1. Write UTF-8 with BOM or plain UTF-8; avoid requiring user interaction.
2. Use `Write-Output` / `Write-Error` for IDE-visible lines (tags like `[ok]` are optional).
3. Do not assume the repo root — check `Test-Path $env:VYRN_IDE_ROOT` when you need repo files.
4. Keep runs short; long jobs should log progress lines.

## Git-0 recipes (optional)

No built-in Git panel yet. Copy and rename:

| File | Purpose |
|------|---------|
| `git_status.ps1.example` | `git status -sb` in `VYRN_IDE_ROOT` |
| `git_log_file.ps1.example` | `git log -3 --` on `VYRN_IDE_FILE` |

Or use **Git-0** slots in `tools.ini.example` (`Git status`, `Git diff` for `{file}`). Requires `git` on PATH.

## Example

`hello_tool.ps1`:

```powershell
Write-Output "[ok] VYRN_IDE_FILE=$env:VYRN_IDE_FILE"
Write-Output "[ok] VYRN_IDE_ROOT=$env:VYRN_IDE_ROOT"
```

Ship a copy of this folder beside `VyrnIDE.exe` (`pack_ide.ps1` includes `extensions\`).
