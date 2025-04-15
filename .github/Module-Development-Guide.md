# PowerShell Module Development Guide

This document provides comprehensive guidance for developing, structuring, and maintaining PowerShell modules in the EguibarIT ecosystem.

## Module Structure

### Standard Folder Organization

```
EguibarIT.ModuleName/
│
├─── .git/                                               # Git specific files
├─── .gitignore                                          # Git ignore file
├─── .github/                                            # GitHub specific files
│   ├─── Copilot/                                        # Copilot prompts
│   │   ├── ad-operations.json
│   │   ├── pester-testing.json
│   │   └── PowerShell-Best-Practices.prompt.md
│   ├─── prompts/                                        # Copilot prompts
│   │   ├── PowerShell-Function-Template.prompt.md
│   │   └── test-template.prompt.md
│   ├─── templates/                                      # templates for issues
│   │   ├── function-template.ps1
│   │   └── function-test--template.ps1
│   └─── workflows/                                      # GitHub Actions workflows
│   │   ├── pipeline.yml
│   │   └── powershell-quality.yml
│   ├─── Code-Style.md                                   # Coding style guide
│   ├─── copilot-instructions.md                         # GitHub Copilot instructions
│   ├─── mcp.json                                        # Module creation prompt
│   └─── Module-Development-Guide.md                     # Module development guide
├─── .vscode/                                            # Visual Studio Code specific files
│   ├── extensions.json                                  # VSCode extensions recommendations
│   ├── launch.json                                      # VSCode launch configuration
│   ├── powershell.code-snippet                          # VSCode code snippets
│   ├── PSScriptAnalyzerSettings.psd1                    # PSScriptAnalyzer settings
│   ├── settings.json                                    # VSCode settings
│   └── tasks.json                                       # VSCode tasks
├─── Classes/                                            # PowerShell classes
├─── Docs/                                               # Documentation files
├─── Enums/                                              # Enumerations
├─── Examples/                                           # Example scripts
├─── Private/                                            # Internal/private functions
├─── Public/                                             # Exported/public functions
│   └─── Logging/                                        # Logging functions
└─── Tests/                                              # Pester tests
├── EguibarIT.ModuleName.psd1                            # Module manifest
├── EguibarIT.ModuleName.psm1                            # Module script file
├── LICENSE                                              # License file
├── README.md                                            # Module documentation
└── CHANGELOG.md                                         # Version history
```

## Module Manifest (PSD1) Requirements

The module manifest (`.psd1`) file is crucial and should include:

```powershell
@{
    # Script module or binary module file associated with this manifest
    RootModule = 'EguibarIT.ModuleName.psm1'

    # Version number of this module
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'New-Guid'  # Use New-Guid to generate

    # Author of this module
    Author = 'Vicente Rodriguez Eguibar'

    # Company or vendor of this module
    CompanyName = 'Eguibar IT'

    # Copyright statement for this module
    Copyright = '(c) 2025 Eguibar IT. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Concise description of the module functionality'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Required modules
    RequiredModules = @()

    # Functions to export from this module
    FunctionsToExport = @('*')

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for discovery
            Tags = @('Windows', 'ActiveDirectory', 'Management')

            # License URI for this module
            LicenseUri = 'https://github.com/vreguibar/EguibarIT.ModuleName/blob/main/LICENSE'

            # Project URI for this module
            ProjectUri = 'https://github.com/vreguibar/EguibarIT.ModuleName'

            # Release notes for this module
            ReleaseNotes = 'https://github.com/vreguibar/EguibarIT.ModuleName/blob/main/CHANGELOG.md'

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance
            # RequireLicenseAcceptance = $false

            # External dependent modules
            # ExternalModuleDependencies = @()
        }
    }
}
```

## Root Module File (PSM1)

The main module script (`.psm1`) file should follow this structure:

```powershell
#Requires -Version 5.1
#Requires -Modules ActiveDirectory

<#
    .SYNOPSIS
        Root module file that loads all components
    .DESCRIPTION
        This is the main module file that loads all functions, classes, and resources
        for the EguibarIT.ModuleName module
#>

#region Module Variables
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
$Script:ModuleRoot = $PSScriptRoot
#endregion Module Variables

# Dot source Enums.
if (Test-Path -Path "$PSScriptRoot\Enums") {
    $Enums = @( Get-ChildItem -Path "$PSScriptRoot\Enums\" -Filter *.ps1 -ErrorAction SilentlyContinue -Recurse )

    # Import Enums
    foreach ($Item in $Enums) {
        Try {
            . $Item.FullName
            Write-Verbose -Message "Imported $($Item.BaseName)"
        } Catch {
            throw
            Write-Error -Message "Could not load Enum [$($Item.Name)] : $($_.Message)"
        } #end Try-Catch
    } #end Foreach
} #end If

# Dot source Classes
if (Test-Path -Path "$PSScriptRoot\Classes") {
    $Classes = @( Get-ChildItem -Path "$PSScriptRoot\Classes\" -Filter *.ps1 -ErrorAction SilentlyContinue -Recurse )

    foreach ($Item in $Classes) {
        Try {
            . $Item.FullName
            Write-Verbose -Message "Imported $($Item.BaseName)"
        } Catch {
            throw
            Write-Error -Message "Could not load Enum [$($Item.Name)] : $($_.Message)"
        } #end Try-Catch
    } #end Foreach
} #end If

#Get public and private function definition files.
$Private = @( Get-ChildItem -Path "$PSScriptRoot\Private\" -Filter *.ps1 -ErrorAction SilentlyContinue -Recurse )
$Public = @( Get-ChildItem -Path "$PSScriptRoot\Public\" -Filter *.ps1 -ErrorAction SilentlyContinue -Recurse )

# Dot source the Public and Private functions
Foreach ($Item in @($Private + $Public)) {
    Try {
        . $Item.fullname
        # Write-Warning $import.fullname
    } Catch {
        Write-Error -Message "Failed to import functions from $($Item.Fullname): $_"
    }
}

# Export public functions
Export-ModuleMember -Function $PublicFunctions.BaseName

# Call function Initialize-ModuleVariable to fill-up $Variables
# . "$PSScriptRoot\Private\Initialize-ModuleVariable"
Initialize-ModuleVariable

```

## Documentation Requirements

### README.md

Your module should include a comprehensive README with:

1. **Module Name and Description** - Clear, concise description of the module's purpose
2. **Installation Instructions** - How to install from PSGallery or GitHub
3. **Requirements** - PowerShell version, OS requirements, and dependencies
4. **Getting Started** - Quick start examples
5. **Key Features** - Highlight major capabilities
6. **Usage Examples** - Common usage scenarios
7. **Parameters and Options** - Explanation of common parameters
8. **Troubleshooting** - Common issues and resolutions
9. **Contributing Guidelines** - How others can contribute
10. **License Information** - Link to the license

### CHANGELOG.md

Maintain a changelog that follows the [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - YYYY-MM-DD
### Added
- Feature A
- Feature B

### Changed
- Behavior X

### Fixed
- Bug Y

## [0.9.0] - YYYY-MM-DD
### Added
- Initial release
```

### LICENSE

Include a LICENSE file appropriate for your project. For open-source projects, common choices include:

- MIT License (permissive)
- Apache License 2.0 (permissive with patent provisions)
- GNU GPL (copyleft)
- Microsoft Public License (Ms-PL)

## Versioning Guidelines

1. Follow [Semantic Versioning](https://semver.org/):
   - MAJOR version for incompatible API changes
   - MINOR version for backward-compatible functionality
   - PATCH version for backward-compatible bug fixes

2. Update version numbers in:
   - Module manifest (`ModuleVersion`)
   - CHANGELOG.md
   - Any version-dependent code

## Testing

### Testing Requirements

1. **Unit Tests** - Test individual functions in isolation
2. **Integration Tests** - Test interactions between components
3. **End-to-end Tests** - Test complete workflows

### Pester Framework

Use Pester 5.x for testing:

```powershell
# Basic test structure
Describe 'Function-Name' {
    BeforeAll {
        # Setup code
    }

    Context 'When used with valid input' {
        It 'Should return expected results' {
            $result = Function-Name -Parameter 'Value'
            $result | Should -Be 'Expected Value'
        }
    }

    Context 'When used with invalid input' {
        It 'Should throw an appropriate error' {
            { Function-Name -Parameter 'Invalid' } | Should -Throw 'Expected error message'
        }
    }

    AfterAll {
        # Cleanup code
    }
}
```

## Publishing to PowerShell Gallery

1. **Preparation**:
   - Ensure all tests pass
   - Update version numbers
   - Update CHANGELOG.md
   - Update README.md

2. **Publish Command**:

```powershell
Publish-Module -Path 'Path\To\ModuleFolder' -NuGetApiKey 'your-api-key' -Repository PSGallery
```

## Module Design Best Practices

1. **Single Responsibility Principle** - Each function should do one thing well
2. **Consistent Parameter Names** - Use standard PowerShell parameter names
3. **Pipeline Support** - Support for pipeline input where appropriate
4. **Proper Error Handling** - Use try/catch blocks and return meaningful errors
5. **Verbose Output** - Include verbose output for debugging
6. **Module Scope** - Use script-scoped variables for internal state
7. **Configuration Management** - Store user settings in appropriate locations

## Additional Resources

- [PowerShell Module Development in a Month of Lunches](https://www.manning.com/books/powershell-module-development-in-a-month-of-lunches)
- [PowerShell Gallery Publishing Guidelines](https://docs.microsoft.com/en-us/powershell/scripting/gallery/concepts/publishing-guidelines)
- [PowerShell Module Manifest Documentation](https://docs.microsoft.com/en-us/powershell/scripting/developer/module/how-to-write-a-powershell-module-manifest)
- [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/)
