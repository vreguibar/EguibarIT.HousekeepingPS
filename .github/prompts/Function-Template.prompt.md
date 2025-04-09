# PowerShell Function Template

Generate a PowerShell function that follows our coding standards and best practices. This function will be part of [EguibarIT.HousekeepingPS] module

## Requirements

- Function Name: {{functionName}}
- Purpose: {{purpose}}
- Target Environment: Active Directory/Windows Server 2019-2022-2025/PowerShell 7
- Required Modules: {{modules}}

## Function Structure

Follow our standard structure:

1. Comment-based help with Synopsis, Description, Parameters, Examples, Notes (including version and Used Functions table), and Links
2. CmdletBinding with appropriate SupportsShouldProcess setting
3. OutputType declaration
4. Parameter block with proper validation and attributes
5. Begin/Process/End blocks
6. Set-StrictMode and module imports in Begin block
7. Error handling with try/catch in Process block
8. Progress reporting for loops
9. End block with completion message

## Coding Standards

- Use PascalCase for all variables
- Use strongly typed variables
- Use single quotes for strings
- Use `-f` operator for string formatting
- Include detailed verbose and debug messages
- Implement ShouldProcess for state-changing operations
- Follow Active Directory tiering model and security best practices
- Optimize for large-scale environments

## Performance Requirements

- Support batch processing
- Optimize for large AD environments (100,000+ objects)
- Minimize redundant queries
- Use efficient filtering with LDAP filters
- Implement pagination for large result sets

## Security Considerations

- Never store credentials in plain text
- Use SecureString for sensitive data
- Implement the least privilege principle
- Sanitize all user input
