---
applyTo: "**"
---
# PowerShell Debugging Guide

This document outlines best practices for debugging PowerShell functions within the `EguibarIT.HousekeepingPS` module ecosystem.

## Table of Contents

1. When to Debug vs. Test
2. Tools and Techniques
3. Suggested Debug Workflow
4. Safe Debugging for Active Directory
5. Copilot-Specific Guidance
6. Common Debugging Pitfalls

## 1. When to Debug vs. Test

| Change Type              | Action Required              |
| :----------------------- | :--------------------------- |
| Comment or help text     | No test or debug required    |
| Style or typo fix        | Lint only                    |
| Parameter default change | Local debug/test if needed   |
| Logic/flow change        | Full Pester test and debug   |
| AD write interaction     | Use -WhatIf + full test      |
| Performance optimization | Measure-Command + coverage   |

## 2. Tools and Techniques

* `Write-Debug`, `Write-Verbose` to trace execution.
* `$DebugPreference = 'Continue'` to enable debug output.
* `Set-PSBreakpoint -Script "Path" -Line 42` for setting breakpoints.
* `-WhatIf` and `-Confirm:$false` for safe preview of operations.
* `Get-Help FunctionName -Full` to validate documentation.
* Avoid making unnecessary changes to the codebase; focus on the specific issue at hand.
* Avoid using `Write-Host` for output; prefer `Write-Output` or `Write-Verbose`.
* Avoid overcomplicating the code while debugging; keep it simple and focused on the issue.
* Use `Measure-Command` to benchmark performance changes where needed.
* Always check for closing brackets. Quite often files get corrupted because of missing closing brackets, which can lead to unexpected behavior.
* Maintain style conventions (e.g., `#end` markers) during debugging to avoid syntax drift.
* Use breakpoints and variable inspection in VS Code’s debugger for interactive sessions.
* Ensure PowerShell extension is configured with the correct profile (avoid loading destructive startup scripts).

## 3. Suggested Debug Workflow

* Use `$ErrorActionPreference = 'Stop'` to enforce consistent error surfacing.
* Set `$ErrorView = 'NormalView'` or `'DetailedView'` for clearer error output.

1. Make a backup of the file being debugged (e.g., My-File.bak).

2. Dot-source your function:

    ```powershell
    . .\Public\My-Function.ps1
    ```

3. Run with verbose/debug flags:

    ```powershell
    My-Function -Identity 'CN=Test' -Verbose -Debug
    ```

4. Use breakpoints or `Write-Verbose` to analyze flow.

5. After confirming fix, run full tests via:

    ```powershell
    Invoke-Pester -Path .\Tests\My-Function.Tests.ps1
    ```

## 4. Safe Debugging for Active Directory

* Use mocked credentials or test domains.
* Prefer `-LDAPFilter` for accurate scope.
* Avoid client-side filtering in production scripts.
* Ensure `ShouldProcess` protects destructive changes.

## 5. Copilot-Specific Guidance

* When suggesting debug enhancements, add `Write-Verbose` and `Write-Debug` strategically—not after every line.
* Use conditional debug messages: `if ($DebugPreference -eq 'Continue') { ... }`.
* Avoid modifying function signatures during debug sessions unless explicitly requested.

## 6. Common Debugging Pitfalls

* Function doesn’t load? Ensure it’s dot-sourced.
* Parameter not binding? Check `ValueFromPipeline` attributes.
* Output missing? Use `Write-Output`, not `Write-Host`.
* `$null` results? Add `Write-Verbose` before and after key logic blocks.
* Missing closing brackets? Verify all opening brackets have corresponding closing ones, especially in complex functions.

---
