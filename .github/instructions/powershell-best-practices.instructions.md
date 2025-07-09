---
applyTo: "**"
---
# PowerShell Best Practices for EguibarIT.HousekeepingPS

This document defines the coding standards and best practices for PowerShell development in our `EguibarIT.HousekeepingPS` module, focusing on manufacturer recommendations and efficient Active Directory operations.

## Table of Contents

1. General Best Practices
2. Active Directory Tiering Model
3. Permission Delegation
4. Identity Management
5. Performance Optimization Techniques
6. Examples
7. References

## 1. General Best Practices

* **Approved Verbs:** Always use approved PowerShell verbs (`Get-Verb` to see list).
* **Parameter Attributes:** Use `Mandatory`, `ValueFromPipeline`, `ValueFromPipelineByPropertyName`, `ValueFromRemainingArguments` where appropriate.
* **Comment-Based help:** Use comment-based help for functions.
* **Advanced Parameters:** Use advanced parameters for better control and usability.
* **Parameter Flexibility:** Provide flexibility with parameters.
* **Detailed Help:** Always include detailed help messages for parameters.
* **`PSDefaultValue`:** Use `PSDefaultValue` for default values, including `Help` message and `Value`.
* **Validation:** Analyze and confirm the use of parameter validation attributes (`ValidateSet`, `ValidatePattern`, `ValidateNotNullOrEmpty`, `AllowNull`, `AllowEmptyString`, `AllowEmptyCollection`, `ValidateCount`, `ValidateLength`, `ValidateRange`, `ValidateScript`).
* **Error Handling:** Implement robust error handling using `try-catch` blocks.
* **Verbose Output:** Use `Write-Verbose` for general information, status, and progress messaging.
* **Single Responsibility Principle:** Each function should do one thing well. Avoid mixing multiple responsibilities in a single function.
* **Module Scope:** Use script-scoped variables for internal state.
* **Configuration Management:** Store user settings in appropriate locations.
* **Idempotency:** Ensure functions can be run multiple times without changing the result beyond the initial execution.
* **Naming Conventions:** Always follow defined naming conventions for functions, parameters, and variables.
* **Documentation:** Comment all blocks of code and provide clear documentation for each function. Explain why it was necessary and why changing it could break things.
* **Helpful Error Messages:** Provide meaningful error messages that help users understand what went wrong and how to fix it.
* **Examples:** Always provide examples in the comment-based help section of each function.
* **WhatIf Support:** Use `WhatIf` and `Confirm` parameters to allow users to preview changes before applying them.
* **Pipeline Support:** Support for pipeline input where appropriate.
* **Action Preferences:** Consider hadling *ActionPreference (`$ErrorActionPreference`, `$WarningPreference`, `$VerbosePreference`, etc.)* to control how errors and warnings are handled in the module.
* **Named Commands:** Use full parameter names instead of positional parameters to improve readability and maintainability.
* **Avoid backtick (`) usage:** Avoid using backticks for line continuation; instead, use parentheses or splatting for multi-line commands.

## 2. Active Directory Tiering Model

* Respect administrative tier boundaries.
* **Tier 0:** Domain controllers, domain admin accounts.
  * Consider logon types and administrative boundaries.
  * Restrict unsecure logon types (e.g., interactive logon) for Tier 0 accounts.
  * Permit unsecure logon types ONLY within the same tier.
* **Tier 1:** Server administrators.
* **Tier 2:** Workstation administrators and user management.
* Ensure functions respect these boundaries with clear documentation.

## 3. Permission Delegation

* Use the least privilege principle for AD operations.
* Document required permissions for each function.
* Use delegation functions in the module to grant only necessary permissions.
Perform a regular review of delegated permissions to ensure they are still appropriate.

## 4. Identity Management

* Accept multiple identity formats (DN, SamAccountName, GUID, SID).
* Handle objects as identity parameters rather than strings when possible.
* Validate identity objects early in the function using module's utility functions. (Refer to [Security Principal Validation Quick Reference](../references/Security-Principal-Validation.instructions.md) for validation functions).

## 5. Performance Optimization Techniques

* **Cache Results:** Cache results when appropriate using module-level variables.
* **Specify Required Properties:** Specify only required Properties when retrieving AD objects.
* **`ServerTimeLimit` and `SizeLimit`:** Use `ServerTimeLimit` and `SizeLimit` when appropriate.
* **Indexed Attribute Searches:** Prefer indexed attribute searches.
* **Starting Processes:** Use `Start-Process` with `-ArgumentList` and `-Wait` avoid blocking the main thread. Include any executable or non-PowerShell script.

## 6. Examples

### Good vs. Bad Practices

```powershell
# Good - uses indexed attributes
Get-ADUser -Filter {SamAccountName -eq 'jsmith'}

# Better - uses LDAP filter with indexed attributes
Get-ADUser -LDAPFilter "(sAMAccountName=jsmith)"

# Avoid - can be slow on large directories (not using indexed attributes)
Get-ADUser -Filter {Description -like '*contractor*'}

# Good - only retrieves needed properties
Get-ADUser -Identity 'jsmith' -Properties SamAccountName, GivenName, Surname

# Avoid - retrieves all properties, which can be inefficient
Get-ADUser -Identity 'jsmith' -Properties *

# Tiering Model Definitions (Example from AD-Operations-QuickRef)
$Tier0OU = "OU=Domain Controllers,DC=contoso,DC=com"
$Tier0Admins = "SG_Tier0Admins"

$Tier1OU = "OU=Tier1,OU=Admin,DC=contoso,DC=com"
$Tier1Admins = "SG_Tier1Admins"

$Tier2OU = "OU=Tier2,OU=Admin,DC=contoso,DC=com"
$Tier2Admins = "SG_Tier2Admins"

# Delegate permissions following tiering model (Example from AD-Operations-QuickRef)
Set-AdAclDelegateComputerAdmin -Group $Tier0Admins -LDAPPath "OU=Domain Controllers,DC=contoso,DC=com"
Set-AdAclDelegateComputerAdmin -Group $Tier1Admins -LDAPPath "OU=Servers,DC=contoso,DC=com"
Set-AdAclDelegateComputerAdmin -Group $Tier2Admins -LDAPPath "OU=Workstations,DC=contoso,DC=com"

# PowerShell Object Creation Best Practices
# Use .NET types for object creation when possible, as they are more efficient and clearer.

# Good - Use .NET types for object creation
[System.Security.Principal.NTAccount]::new($Identity)

[System.Security.AccessControl.FileSystemAccessRule]::new(
  $Account,
  $FileSystemRights,
  $InheritanceFlags,
  $PropagationFlags,
  $AccessControlType
)

# Avoid unless justified reason (no other way to create the object)
# Bad - Using New-Object for object creation, which is less efficient
New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList $Identity

New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList (
    $Account,
    $FileSystemRights,
    $InheritanceFlags,
    $PropagationFlags,
    $AccessControlType
  )

# string formatting
# Good - Use String formatting for clarity and maintainability
$SetupArgs.Add('/INSTANCENAME={0}' -f $InstanceName)
$SetupArgs.Add('/INSTANCEDIR="{0}"' -f $InstallDir)

# Bad -avoid using backtick for line continuation. Avoid having variables within strings using double quotes.
$SetupArgs.Add("/INSTANCENAME=`"$InstanceName`"")
$SetupArgs.Add("/INSTANCEDIR=`"$InstallDir`"")
```

## 7. References

* [PowerShell Module Development in a Month of Lunches](https://www.manning.com/books/powershell-module-development-in-a-month-of-lunches)
