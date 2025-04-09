# GitHub Copilot Global Instructions

## Language

PowerShell, version 7+, following strict professional, secure, and maintainable coding standards.

## Expectations

- Write functions as part of [EguibarIT.HousekeepingPS] PowerShell module, supporting Active Directory & Windows environments (Windows Server 2019–2025).
- Follow tiered AD model and best security practices.
- Optimize for scalability: 100,000+ objects.
- Implement thorough parameter validation and comment-based help.
- Include proper structure (CmdletBinding, Begin/Process/End, etc).
- Maintain consistent style (PascalCase, strongly typed variables, 120-character line limit).
- Write efficient, idempotent code with caching, pagination, and AD indexing where applicable.
- Every function should be tested with Pester and include performance and error-path validation.

## Code Style

- Always include comment-based help, Write-Verbose, proper error handling.
- Use Set-StrictMode, constants, and well-documented blocks.
- Avoid deep nesting, use helper functions.

## Testing

- Include Pester tests with [FunctionName].Tests.ps1.
- Mock external dependencies.

## Function Design

When suggesting PowerShell functions:

Always include these structural elements:

- Complete comment-based help (Synopsis, Description, Parameters, Examples, Notes)
- [CmdletBinding()] with appropriate attributes
- OutputType specification
- Begin/Process/End blocks
- Proper error handling with try/catch

Parameter design:

- Include mandatory attribute where appropriate
- Include proper parameter validation
- Include help messages
- Support pipeline input where appropriate
- Use parameter sets when needed

Begin block should include:

- Set-StrictMode -Version Latest
- Required module imports
- Variables and constants definitions

Error handling:

- Use try/catch blocks with specific error types
- Use appropriate messaging cmdlets (Verbose, Debug, Warning, Error)

## Code Style

Naming:

- Use PascalCase for variables and functions
- Use descriptive names that indicate purpose

Formatting:

- Maximum line length: 120 characters
- Use single quotes for strings
- Use string formatting ('Text {0}' -f $variable)
- Include end-of-block comments (} #end BlockName)

Security:

- Never include hardcoded credentials
- Sanitize user input
- Use SecureString for sensitive data

Best Practices:

- Implement ShouldProcess for functions that make changes
- Use parameter validation
- Include progress indicators for lengthy operations
- Cache results to minimize redundant queries

## Module Integration

Structure:

Follow module folder structure (Public/Private/Classes/Enums/Tests)

- Respect module naming conventions
- Leverage existing module helper functions

Performance:

- Optimize for large environments
- Use efficient filtering methods
- Implement pagination for large result sets

Testing:

- Include Pester test framework files
- Mock external dependencies
- Test all parameter combinations and edge cases
