# PowerShell Best Practices for EguibarIT.HousekeepingPS

This document defines the coding standards and best practices for PowerShell development in our EguibarIT.HousekeepingPS module.

## Naming Conventions

1. **Functions:**
   - Use PascalCase in Verb-Noun format
   - Always use approved PowerShell verbs (`Get-Verb` to see list)
   - Use singular nouns
   - Example: `Get-ADUserInfo` not `GetUserInformation`

2. **Variables:**
   - Use PascalCase for all variables
   - Example: `$UserDN` not `$userdn` or `$user_dn`

3. **Parameters:**
   - Use PascalCase
   - Include mandatory parameters where appropriate
   - Use `Mandatory` attribute for required parameters
   - Always use `ValueFromPipeline`, `ValueFromPipelineByPropertyName` and `ValueFromRemainingArguments` and provide if true or false
   - Always include detailed help message
   - ALways include Position attribute for parameters
   - Use standard parameter names where appropriate (Identity, Path, etc.)
   - Use validation for parameters (e.g., `ValidateSet`, `ValidatePattern`, `ValidateNotNullOrEmpty`, etc.)

## Code Formatting

1. **Indentation:** Use 4 spaces for indentation (not tabs)

2. **Braces:** Opening brace on the same line, closing brace on a new line

   ```powershell
   function Get-Example {
       # Function content
   } #end function Get-Example
   ```

3. **Comments:** End each code block with a comment indicating what's being closed

   ```powershell
   if ($condition) {
       # Code
   } #end if

   foreach ($item in $collection) {
       # Code
   } #end foreach
   ```

4. **String Formatting:** Use `-f` operator for string formatting

   ```powershell
   'User {0} has {1} roles' -f $UserName, $RoleCount
   ```

5. **Line Length:** Keep lines under 130 characters

## Documentation

1. **Comment-Based Help:** All functions must include comment-based help with:
   - Synopsis
   - Description
   - Parameter descriptions
   - Examples
   - Input and output types
   - Notes section with used functions (search within script for used functions/CMDlets)
   - Notes section with version control, date, and author information
   - Link to GitHub repository
   - Link to any related documentation or resources
   - Component
   - Role
   - Functionality

2. **Code Comments:**
   - Include comments for complex logic or business rules
   - Use `#region` and `#endregion` for large blocks of code
   - Use extended documentation for code

## Error Handling

1. **Try/Catch Blocks:** Use specific exception types where possible

   ```powershell
   try {
       # Operation that might fail
   } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
       Write-Warning -Message ('Identity not found: {0}' -f $Identity)
   } catch {
       Write-Error -Message ('General error: {0}' -f $_.Exception.Message)
   }
   ```

2. **ShouldProcess:** Include for functions that change state

   ```powershell
   if ($PSCmdlet.ShouldProcess($Identity, 'Disable user account')) {
       # Perform the operation
   }
   ```

## Performance Considerations

1. **LDAP Filters:** Use LDAP filters instead of client-side filtering

   ```powershell
   Get-ADUser -LDAPFilter "(samAccountName=$SamAccountName)"
   # Instead of
   Get-ADUser -Filter * | Where-Object { $_.SamAccountName -eq $SamAccountName }
   ```

2. **Properties Selection:** Only request properties you need

   ```powershell
   Get-ADUser -Identity $Identity -Properties DisplayName, Title, Department
   # Instead of
   Get-ADUser -Identity $Identity -Properties *
   ```

3. **Pipeline Usage:** Favor the pipeline for large data processing

## Security Considerations

1. **Credential Handling:** Never hardcode credentials
   - Use `PSCredential` objects
   - Consider using the Windows Credential Manager

2. **Parameter Validation:** Always validate inputs
   - Use `ValidateNotNull`, `ValidateNotNullOrEmpty`, `ValidateScript`, etc.

3. **Least Privilege:** Functions should request only the access they need

## Testing Requirements

1. **Pester Tests:** Include tests for each function
   - Parameter validation tests
   - Functionality tests
   - Error handling tests
   - Mock external dependencies

2. **Test Coverage:** Aim for >80% code coverage
