---
applyTo: "**"
---
# PowerShell Module Development Guide

This document provides comprehensive guidance for developing, structuring, and maintaining PowerShell modules in the `EguibarIT.HousekeepingPS` ecosystem.

## Table of Contents

1. Module Structure
2. Module Design Best Practices
3. Pester Testing Integration
4. Publishing to PowerShell Gallery
5. Additional Resources

## 1. Module Structure

### Copilot Hints

* When generating module scaffolding, follow this folder layout.
* Prefer existing templates in `./templates/` unless a unique structure is required.
* When generating new module components, ensure test scaffolding and code snippets are aligned with the `Code-Style.instructions.md` and `Debugging-Guide.instructions.md`.

### Standard Folder Organization

EguibarIT.HousekeepingPS/
│
├─── .git/                                                 # Git specific files
├─── .gitignore                                            # Git ignore file
├─── .github/
│   ├── mcp.json                                           # Your main Copilot configuration file
│   ├── copilot-instructions.md                              # Instructions for Copilot itself
│   ├── instructions/                                      # Copilot instructions files
│   |   ├── Code-Style.instructions.md                       # Instructions for Copilot on code style
│   |   ├── Debugging-Guide.instructions.md                  # Instructions for Copilot on debugging
│   |   ├── Module-Development-Guide.instructions.md         # Instructions for Copilot on module development
│   |   ├── powershell-best-practices.instructions.md        # Instructions for Copilot on PowerShell best practices
│   |   └── test.instructions.md                             # Instructions for Copilot on testing
│   ├── patterns/                                          # For JSON files defining structured code patterns and snippets
│   |   ├── ad-operations.json                               # AD operations patterns
│   |   ├── copilot-enhanced-context.json                    # Copilot enhanced context patterns
│   |   └── pester-testing.json                              # Pester testing patterns
│   ├── prompts/                                           # For .prompt.md files that define conversational prompts
│   |   ├── PowerShell-Function-Template.prompt.md           # PowerShell function template prompt
│   |   └── test-template.prompt.md                          # Pester test template prompt
│   ├── references/                                        # For general Markdown reference documents and examples
│   |   ├── AD-Operations-QuickRef.instructions.md           # Quick reference for AD operations
│   |   ├── copilot-advanced-patterns.instructions.md        # Advanced Copilot patterns
│   |   ├── Copilot-Automation-Examples.instructions.md      # Examples of Copilot automation
│   |   └── Security-Principal-Validation.instructions.md    # Security principal validation quick reference
│   └── templates/                                         # For example function/test templates that can be used directly or by Copilot
│   |   ├── function-template.ps1                            # PowerShell function template
│   |   └── function-test-template.ps1                       # PowerShell function test template
│   └── workflows/                                         # For GitHub Actions workflows
│   |   ├── pipeline.yml                                      # Main CI/CD pipeline configuration
│   |   └── powershell-quality.yml                            # PowerShell quality checks workflow
├─── .vscode/                                              # Visual Studio Code specific files
│   ├── extensions.json                                      # VSCode extensions recommendations
│   ├── launch.json                                        # VSCode launch configuration
│   ├── powershell.code-snippet                              # VSCode code snippets
│   ├── PSScriptAnalyzerSettings.psd1                        # PSScriptAnalyzer settings
│   ├── settings.json                                        # VSCode settings
│   └── tasks.json                                           # VSCode tasks
├─── Classes/                                              # PowerShell classes
├─── Docs/                                                 # Documentation files
├─── Enums/                                                # Enumerations
├─── Examples/                                             # Example scripts
├─── Private/                                              # Internal/private functions
├─── Public/                                               # Exported/public functions
│   └─── Logging/                                            # Logging functions
└─── Tests/                                                # Pester tests
├── EguibarIT.HousekeepingPS.psd1                            # Module manifest
├── EguibarIT.HousekeepingPS.psm1                            # Module script file
├── LICENSE                                                # License file
├── README.md                                              # Module documentation
└── CHANGELOG.md                                           # Version history

### Manifest (`.psd1`) Guidelines

* Always include `RequiredModules`, `FunctionsToExport`, and `CmdletsToExport`.
* Use `PrivateData` for versioning or tagging.

### Script Module (`.psm1`) Guidelines

* Load public/private functions via `Get-ChildItem` and `Dot-Sourcing`.
* Never hard-code paths; always use `$PSScriptRoot`.
* Avoid logic in the module root; define functions only.

## 2. Module Design Best Practices

* **Single Responsibility Principle:** Each function should do one thing well.
* **Consistent Parameter Names:** Use standard PowerShell parameter names.
* **Pipeline Support:** Support for pipeline input where appropriate.
* **Proper Error Handling:** Use try/catch blocks and return meaningful errors. (Refer to [Code Style Guide](./Code-Style.instructions.md) for detailed error handling).
* **Verbose Output:** Include verbose output for debugging and tracing.
* **Module Scope:** Use script-scoped variables for internal state.
* **Configuration Management:** Store user settings in appropriate locations.
* **Idempotency:** Ensure functions can be run multiple times without changing the result beyond the initial execution.

## 3. Pester Testing Integration

* All module functions should have corresponding Pester tests.
* Test files should follow the convention: `[FunctionName].Tests.ps1`.
* Test files should reside in the `.\Tests\` folder within the module.
* **Basic Test Structure Example:**

    ```powershell
    BeforeAll {
        # Import module
        $ModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\\..\\{{moduleName}}.psd1'
        Import-Module -Name $ModulePath -Force

        # Mock dependencies (Example from pester-testing.json)
        Mock -CommandName Get-ADUser -MockWith {
            # Return mock data
        }
    }

    Describe '{{functionName}}' {
        Context 'Parameter validation' {
            It 'Should throw when required parameters are not provided' {
                { {{functionName}} } | Should -Throw
            }
        }

        Context 'Function behavior' {
            It 'Should return expected results' {
                $Result = {{functionName}} -Identity 'TestUser'
                $Result | Should -Not -BeNullOrEmpty
            }

            It 'Should call expected AD cmdlets' {
                $Result = {{functionName}} -Identity 'TestUser'
                Should -Invoke -CommandName Get-ADUser -Times 1 -Exactly
            }
        }

        Context 'Error handling' {
            It 'Should handle non-existent objects gracefully' {
                Mock -CommandName Get-ADUser -MockWith { throw [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]::new() }
                $Result = {{functionName}} -Identity 'NonExistent' -ErrorAction SilentlyContinue
                $Result | Should -BeNull
            }
        }
    }

    AfterAll {
        # Cleanup code
    }
    ```

* Refer to [Pester Test Template Prompt](../prompts/test-template.prompt.md) for a comprehensive Pester test template.

## 4. Publishing to PowerShell Gallery

* **Preparation:**
  * Ensure all tests pass.
  * Update version numbers.
  * Update `CHANGELOG.md`.
  * Update `README.md`.
* **Publish Command:**

    ```powershell
    Publish-Module -Path 'Path\To\ModuleFolder' -NuGetApiKey 'your-api-key' -Repository PSGallery
    ```

## 5. Additional Resources

* [PowerShell Module Development in a Month of Lunches](https://www.manning.com/books/powershell-module-development-in-a-month-of-lunches)
* [PowerShell Gallery Publishing Guidelines](https://docs.microsoft.com/en-us/powershell/scripting/gallery/concepts/publishing-guidelines)
* [PowerShell Module Manifest Documentation](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest)
