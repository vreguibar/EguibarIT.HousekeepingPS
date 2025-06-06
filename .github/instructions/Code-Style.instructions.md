---
applyTo: "**"
---
# PowerShell Coding Style Guide

This document serves as the primary source of truth for coding style and best practices for PowerShell functions in `EguibarIT.HousekeepingPS` module. GitHub Copilot and all developers should adhere to these standards.

## Table of Contents

1. Structure
2. Naming Conventions
3. Code Structure
4. Variable Handling
5. Code Formatting
6. Error Handling & Logging
7. Security & Performance
8. Copilot Instruction Hints
9. Testing
10. Documentation
11. Tooling & Automation
12. End Markers
13. Used CMDlets/Functions table
14. Change Control table

## 1. Structure

* **Public Functions:** Reside in `Public/` folder.
* **Private/Internal Functions:** Reside in `Private/` folder.
* **Classes:** Reside in `Classes/` folder.
* **Enumerations:** Reside in `Enums/` folder.
* **Pester Tests:** Reside in `Tests/` folder.
* **Module Documentation:** Reside in `Docs/` folder.
* **Module Examples:** Reside in `Example/` folder.

## 2. Naming Conventions

* **Functions:** Use approved PowerShell verbs (`Get-Verb` to see list).
  * File names should match function names (e.g., `Get-ADUser.ps1` for `Get-ADUser` function).
  * Use PascalCase in Verb-Noun format (e.g., `Get-ADUserPermission`, `Set-GroupPolicyRights`).
  * Use singular nouns.
  * Use descriptive names that clearly indicate the function's purpose.
  * Avoid abbreviations unless commonly understood.
* **Parameters:** Use PascalCase.
  * Choose descriptive names.
  * Use strongly typed parameters (e.g., `[string]$UserName`, `[int]$MaxResults`).
  * Include `Mandatory` attribute where appropriate (`$true` or `$false`).
  * Use `ValueFromPipeline`, `ValueFromPipelineByPropertyName`, and `ValueFromRemainingArguments` where appropriate.
  * Include detailed help messages.
  * Include `Position` attribute for important parameters.
  * Use standard parameter names (Identity, Path, etc.).
  * Use `PSDefaultValue` for default values including `Help` message and `Value`.
  * Do not rename existing parameters to mantain backward compatibility.
* **Parameter Validation:** Analyze and confirm the use of validation attributes:
  * `AllowNull` and `AllowEmptyString` for parameters that can accept null or empty values.
  * `AllowEmptyCollection` for parameters that can accept empty collections.
  * `ValidateCount` for parameters that accept a specific number of items.
  * `ValidateLength` for parameters that must have a specific length.
  * `ValidatePattern` for parameters that must match a regular expression.
  * `ValidateRange` for numerical parameters within a specific range.
  * `ValidateSet` for parameters with a limited set of valid values.
  * `ValidateScript` for custom validation logic.
* **Classes:** Use PascalCase with a suffix indicating the type (e.g., `ADUser`, `ADGroupPolicy`).
  * File names should start with `Class.` followed by matching class names (e.g., `Class.ADUser.ps1` for `ADUser` class).

## 3. Code Structure

* Always use advanced functions by providing `CmdletBinding()` at the start of the function.
  * Always use `SupportsShouldProcess`. For functions that change state set it to `$true`, otherwise `$false`.
  * Always evaluate the impact of the operation using `ShouldProcess` and specify the impact level (`Low`, `Medium`, `High`).
  * If more than 1 `ParameterSet` is required, use `ParameterSetName` to define the function default.
* Always provide a return type using the `ReturnType` attribute in `CmdletBinding()`. Use `[Void]` for functions that do not return a value.
* Return consistent object structures when appropriate.
* Use `PSDefaultValue` for default parameter values, including help messages.
* Use `Set-StrictMode -Version Latest` in the `Begin` block.
* Implement `Begin`, `Process`, and `End` blocks for functions.
* Always provide a section within Begin block for Module Initialization
* Always provide a section within Begin block for Variables Definition.
* Functions should be idempotent.

## 4. Variable Handling

* **Variables:** Use PascalCase for all variables (e.g., `$UserDN`, `$ADObject`).
* Always use strongly typed variables (e.g., `[string]$variableName`, `[int]$count`).
* Always initialize variables before use within the `Begin` section. Justify why if those are created in the `Process` section.
* Avoid abbreviations unless commonly understood.
* Use `Arrays` only when fixed size. Prefer using `System.Collections.Generic.List` for changing size collections.
* Use `Collections` evenly across the module. Consider compatibility between functions.
* Use `HashSet` for unique collections of items.
* Use `Hashtable` for key-value pairs. Prefer `[ordered]` hashtables for maintaining order.
* Use `PSCustomObject` for structured data output.
* Use `StringBuilder` for complex string manipulations.
* Ensure output object properties follow a logical and predictable order (e.g., `Name`, `DistinguishedName`, `Enabled`, `Description`).
* Use `[ordered]` hashtables where consistent display or formatting is required.


## 5. Code Formatting

* **Indentation:** Use 4 spaces for indentation (not tabs).
* **Braces:** Opening brace on the same line, closing brace on a new line. Reger to `11. End Markers` for end markers.
* **Line Breaks:** Use line breaks for readability, especially in long lines or complex expressions.
* **Comments:** End each code block with a corresponding `#end` marker. Use above-line comments for complex logic.
* **Line Length:** Limit lines to 120 characters.
* **Whitespace:** Use single blank lines to separate logical sections of code. Avoid trailing whitespace.
* **String Formatting:** Use single quotes for strings. Use the `-f` operator for string formatting.
* **Line separators:** Use empty lines to separate logical blocks of code, especially between `Begin`, `Process`, and `End` blocks.
* **Pipeline Input:** Use `ValueFromPipeline` and `ValueFromPipelineByPropertyName` for parameters that accept pipeline input.
* **Parameter Sets:** Use `ParameterSetName` to define different sets of parameters for a function.

## 6. Error Handling & Logging

* Use `try-catch-finally` blocks for robust error handling.
* Use `Write-Error -ErrorAction Stop` for terminating errors.
* Use `Write-Warning` for non-terminating errors or warnings.
* Use `Write-Verbose` for general information, status, and progress messaging.
* Use `Write-Debug` for debugging information.
* Provide meaningful error messages.

## 7. Security & Performance

* Never store credentials or sensitive data in plain text.
* Use `SecureString` for password parameters.
* Implement the least privilege principle.
* Sanitize all user input before using it in queries.
* Avoid using `Invoke-Expression` with user-supplied input.
* Use credential parameters with proper validation (e.g., `[System.Management.Automation.PSCredential]`).
* Optimize for large-scale Active Directory environments (100,000+ objects).
* Cache results when appropriate using module-level variables.
* Specify only required properties when retrieving AD objects.
* Use `ServerTimeLimit` and `SizeLimit` when appropriate.
* Prefer indexed attribute searches over non-indexed ones for performance.
* Implement appropriate pagination for large result sets.

## 8. Copilot Instruction Hints

* If multiple patterns are possible, suggest the most readable and maintainable first, and annotate why.
* Always format generated code with end markers.
* When pasting or completing partial code, align output with the surrounding style automatically.

## 9. Testing

* Include Pester test files with naming convention `[FunctionName].Tests.ps1`.
* Cover parameter validation, functionality, error handling, edge cases.
* Mock external dependencies for independent testing.
* Test pipeline input scenarios.
* Test `ShouldProcess` functionality where implemented.
* Consider including performance tests for functions that handle large datasets.

## 10. Documentation

* **Function Documentation:** Use comment-based help for all functions. Include:
  * `.SYNOPSIS`: Brief description of function purpose.
  * `.DESCRIPTION`: Detailed description of function functionality.
  * `.PARAMETER ParameterName`: Description of parameter purpose, expected values, and behavior.
  * `.EXAMPLE`: Example usage with description.
  * `.INPUTS`: .NET types of objects that can be piped to the function.
  * `.OUTPUTS`: .NET type of the objects that the cmdlet returns.
  * `.NOTES`: Used CMDlets/Functions table as described `Used CMDlets/Functions table`
  * `.NOTES`: Used change control table as described `Change Control Table`
  * `.LINK`: Github repository and specific function.
  * `.LINK`: Relevant documentation or external resources.
  * `.COMPONENT`: The component or module the function belongs to.
  * `.ROLE`: The administrative role required to run the function.
  * `.FUNCTIONALITY`: A high-level description of what the function does.
* **Comment-Based help location**: Place comment-based after the function and before `CmdletBinding()`.
* Ensure all tooling and Copilot prompts are tuned to parse help blocks placed after the function declaration.
* Document code blocks and include in-line documentation with clear comments.

## 11. Tooling & Automation

* **EditorConfig:** Enforce indentation and line length.
* **PSScriptAnalyzer:** Use custom ruleset aligned with this guide.
* **Git Hooks:** Pre-commit check for style compliance.
* **Copilot Prompting:** Reference `.prompt.md` and `.json` files.
* **Pester Tests:** Use `Invoke-Pester` for running tests.
* **PlatyPS:** Use for generating and maintaining module documentation.

## 12. End Markers

* Ensure pre-commit hooks strip or validate `#end` markers where CI/CD or automation tools may not tolerate them.

Explicitly mark the end of code blocks with corresponding `#end` markers:

| Block Type          | Required End Marker        |
| :------------------ | :------------------------- |
| `Function`          | `#end Function <Name>`     |
| `Begin`             | `#end Begin`               |
| `Process`           | `#end Process`             |
| `End`               | `#end End`                 |
| `If`                | `#end If`                  |
| `If-Else`           | `#end If-Else`             |
| `If-ElseIf`         | `#end If-ElseIf`           |
| `If-ElseIf-Else`    | `#end If-ElseIf-Else`      |
| `Try-Catch`         | `#end Try-Catch`           |
| `Try-Catch-Finally` | `#end Try-Catch-Finally`   |
| `ForEach`           | `#end ForEach`             |
| `For`               | `#end For`                 |
| `Switch`            | `#end switch`              |
| `While`             | `#end While`               |
| `Do-While`          | `#end Do-While`            |

## 13. Used CMDlets/Functions table

This example table will contain every CMDlet or Function used in the code block, including the module or namespace it belongs to. This is useful for understanding dependencies and ensuring that all required modules are imported.

```powershell
# Used CMDlets/Functions table
  .NOTES
    Used Functions:
      Name                                       ║ Module/Namespace
      ═══════════════════════════════════════════╬══════════════════════════════
      Get-ADObject                               ║ ActiveDirectory
      Write-Verbose                              ║ Microsoft.PowerShell.Utility
      Get-FunctionDisplay                        ║ EguibarIT
  ```

## 14. Change Control table

This section is used to track changes made to the code block, including version updates, date of modification, and the person who last modified it. This is useful for maintaining a history of changes and ensuring accountability.

* Increase version if existing. Start at 1.0 for new code blocks.
* Add or update date of modification.
* Add last modified by information.

  ```powershell
    .NOTES
      Version:         1.2
      DateModified:    7/Apr/2025
      LastModifiedBy:  Vicente Rodriguez Eguibar
                vicente@eguibarit.com
                Eguibar IT
                http://www.eguibarit.com
  ```
