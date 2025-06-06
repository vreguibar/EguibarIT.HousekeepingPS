---
applyTo: "**"
---
# Active Directory Operations Quick Reference

This quick reference provides commonly used patterns and examples for Active Directory operations in the EguibarIT module.

## Table of Contents

1. Identity Validation
2. LDAP Filter Patterns
3. AD Tiering Model Delegation Examples
4. Performance Optimization Techniques
5. Private Helper Functions
6. Module Variables and Constants
7. Module Classes

## 1. Identity Validation

### Validate Distinguished Name (DN)

```powershell
# Using Test-IsValidDN Function (from Security-Principal-Validation.md)
function Get-AdObjectDetails {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'Distinguished Name provided is not valid! Please check format.'
        )]
        [String]$Identity
    )
    # Function implementation
}

# Complex DN Validation (from Security-Principal-Validation.md)
function Set-AdPermissions {

    param(

        [Parameter(Mandatory = $true)]
        [ValidateScript({
            if (-not (Test-IsValidDN -ObjectDN $_)) {
                throw ('Invalid distinguished name format: {0}' -f $_)
            } #end if
            # Additional validation - check if DN exists in AD
            try {
                Get-ADObjectType -Identity $_ -ErrorAction Stop | Out-Null
                return $true
            } catch {
                throw ('Object not found in AD: {0}' -f $_)
            } #end try-catch
        })]
        [String]$TargetDN
    )
    # Function implementation
}
```

### Validate Security Identifier (SID)

```PowerShell
# Using Test-IsValidSID Function (from Security-Principal-Validation.md)
function Get-SecurityPrincipal {

    param(

        [Parameter(Mandatory = $false)]
        [ValidateScript(
            { Test-IsValidSID -ObjectSid $_ },
            ErrorMessage = 'Security Identifier (SID) provided is not valid! Please check format.'
        )]
        [String]
        $SID
    )
    # Function implementation
}
```

## 2. LDAP Filter Patterns

| Scenario                    | LDAP Filter                                                                          | Notes    |
|-----------------------------|--------------------------------------------------------------------------------------|----------|
| Users in Group              | (&(objectCategory=person)(objectClass=user)(memberOf=CN=GroupName,OU=Groups,DC=contoso,DC=com)) | Direct membership only |
| Computers in OU             | (&(objectCategory=computer)(objectClass=computer)) | Use with SearchBase parameter   |
| Disabled Users              | (&(objectCategory=person)(objectClass=user)(userAccountControl:1.2.840.113556.1.4.803:=2)) | Uses bitwise filter |
| Expired Accounts            | (&(objectCategory=person)(objectClass=user)(accountExpires<=129473172000000000))     | Replace with current time in FILETIME format |
| Users by Department         | (&(objectCategory=person)(objectClass=user)(department=IT)) | Exact match on department |
| Users with specific Manager | (&(objectCategory=person)(objectClass=user)(manager=CN=ManagerName,OU=Users,DC=contoso,DC=com)) | |
| Users with specific Title   | (&(objectCategory=person)(objectClass=user)(title=Manager)) | Exact match on title   |

## 3. AD Tiering Model Delegation Examples

````powershell
    # Tiering Model Definitions
    $Tier0OU = "OU=Domain Controllers,DC=contoso,DC=com"
    $Tier0Admins = "SG_Tier0Admins"

    # Tier 1 - Server Administrators
    $Tier1OU = "OU=Tier1,OU=Admin,DC=contoso,DC=com"
    $Tier1Admins = "SG_Tier1Admins"

    # Tier 2 - Workstation Administrators
    $Tier2OU = "OU=Tier2,OU=Admin,DC=contoso,DC=com"
    $Tier2Admins = "SG_Tier2Admins"

    # Delegate permissions following tiering model
    Set-AdAclDelegateComputerAdmin -Group $Tier0Admins -LDAPPath "OU=Domain Controllers,DC=contoso,DC=com"
    Set-AdAclDelegateComputerAdmin -Group $Tier1Admins -LDAPPath "OU=Servers,DC=contoso,DC=com"
    Set-AdAclDelegateComputerAdmin -Group $Tier2Admins -LDAPPath "OU=Workstations,DC=contoso,DC=com"
````

## 4. Performance Optimization Techniques

### Use Indexed Attributes

```powershell
# Good - uses indexed attributes
Get-ADUser -Filter {SamAccountName -eq 'jsmith'}

# Better - uses LDAP filter with indexed attributes
Get-ADUser -LDAPFilter "(sAMAccountName=jsmith)"

# Avoid - non-indexed attributes
Get-ADUser -Filter {Description -like '*contractor*'}
```

### Request Only Needed Properties

```powershell
# Good - only retrieves needed properties
Get-ADUser -Identity 'jsmith' -Properties SamAccountName, GivenName, Surname
```

## 5. Private Helper Functions

This module implements several private helper functions to streamline common tasks. Consider using these first before implementing new functions:

* `Get-ADCSTemplate`: Returns properties of Active Directory Certificate Template.
* `Get-AdObjectType`: Returns the type of an AD object based on its identity. Key element for identity validation; a variable representing an identity can be parsed to this function to determine its type, avoiding additional queries to AD.
* `Get-FunctionDisplay`: Returns a formatted display string for a function. Most of the functions use it for Header display.
* `Get-IniContent`: Reads and parses an INI file content.
* `Get-RandomHex`: Generates a random hexadecimal string.
* `Get-SafeVariable`: Retrieves a variable value safely, handling null or empty cases.
* `Initialize-EventLogging`: Initializes event logging for the module.
* `Initialize-ModuleVariables`: Initializes module-level variables.
* `New-Template`: Creates a new template object for AD operations.
* `New-TemplateOID`: Creates a new template OID object for AD operations.
* `Out-IniFile`: Outputs data to an INI file format.
* `Publish-CertificateTemplate`: Publishes a certificate template to Active Directory.
* `Test-IsUniqueOID`: Validates if an OID is unique within the AD environment.
* `Test-IsValidDN`: Validates Distinguished Names.
* `Test-IsValidGUID`: Validates GUIDs.
* `Test-IsValidSID`: Validates Security Identifiers.

## 6. Module Variables and Constants

This module has defined several variables and constants that are used throughout the module for various operations.
Those files are being loaded (dot-sourced) from module PSM1 file, starting by `./Enums/` folder and followed by `./Classes/` folder.

Defined `$Variable` initializates several inner variables.
Those definitions are within the `./Enums/` folder, having `Enum.Encoding.cs`, `Enum.ServiceAccessFlags.cs`, `Enum.ServiceControlManagerFlags.cs`, `Enum.Variables.ps1` and `Enum.WellKnownSids.ps1`.
The following table shows empty variables, which are initialized to ensure consistency across the module.
In a latter step, these variables are populated by the `Initialize-ModuleVariable` function.

| Variable Name                             | Content                                                                          |
|-------------------------------------------|----------------------------------------------------------------------------------|
| `$Variables.AdDN`                         |  Active Directory DistinguishedName                                              |
| `$Variables.configurationNamingContext`   |  Configuration Naming Context                                                    |
| `$Variables.defaultNamingContext`         |  Default Naming Context                                                          |
| `$Variables.DnsFqdn`                      |  current DNS domain name                                                         |
| `$Variables.ExtendedRightsMap`            |  Hashtable containing the mappings between SchemaExtendedRights and GUIDs        |
| `$Variables.GuidMap`                      |  Hashtable containing the mappings between ClassSchema/AttributeSchema and GUIDs |
| `$Variables.namingContexts`               |  Naming Contexts                                                                 |
| `$Variables.PartitionsContainer`          |  Partitions Container                                                            |
| `$Variables.rootDomainNamingContext`      |  Root Domain Naming Context                                                      |
| `$Variables.SchemaNamingContext`          |  Schema Naming Context                                                           |
| `$Variables.WellKnownSIDs`                |  Ordered hashtable containing Well-Known Sids mappings                           |

The other variables (static variables) that are defined and loaded at this point.

Defined `$Constants` initialized and loaded with values in READ-ONLY mode.
This is defined within the `./Enums/` folder, having `Enum.Constants.ps1` file.

## 7. Module Classes

This module implements only 1 class: `EguibarIT.Delegation.Class.Events`.
This class is used to handle event logging and management within the module.
The `./Classes/Class.Events.cs` file contains the requiered event classes, which is used for event logging and management within the module.
All C# files are loaded by the `./Classes/Class.LoadCSharpFiles.ps1` file.
