# Security Principal Validation Quick Reference

This quick reference provides examples and functions for validating security principals (users, groups, computers) in the EguibarIT.HousekeepingPS module.

## Table of Contents

1. Distinguished Name (DN) Validation
2. Security Identifier (SID) Validation
3. GUID Validation
4. Validating Object Existence
5. Converting Identity to SID
6. Working with Well-Known SIDs
7. Related Documentation

## 1. Distinguished Name (DN) Validation

### Using Test-IsValidDN Function

This utility function `Test-IsValidDN` would be part of the EguibarIT.HousekeepingPS module and is used for validating the format of a Distinguished Name.

```powershell
function Get-AdObjectDetails {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'Distinguished Name provided is not valid! Please check format.'
        )]
        [String]$Identity
    )
    # Function implementation would proceed here after validation
}
```

### Complex DN Validation with Existence Check

This example combines format validation with an Active Directory existence check.

```powershell
function Set-AdPermissions {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({
            # Validate DN format first
            if (-not (Test-IsValidDN -ObjectDN $_)) {
                throw ('Invalid distinguished name format: {0}' -f $_)
            }

            # Additional validation - check if DN exists in AD
            try {
                Get-ADObject -Identity $_ -ErrorAction Stop | Out-Null
                return $true
            } catch {
                throw ('Object not found in AD: {0}' -f $_)
            }
        })]
        [String]$TargetDN
    )
    # Function implementation would proceed here after validation
}
```

## 2. Security Identifier (SID) Validation

### Using Test-IsValidSID Function

This utility function `Test-IsValidSID` would be part of the EguibarIT.HousekeepingPS module and is used for validating the format of a Security Identifier.

```powershell
function Get-SecurityPrincipal {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateScript(
            { Test-IsValidSID -ObjectSid $_ },
            ErrorMessage = 'Security Identifier (SID) provided is not valid! Please check format.'
        )]
        [String]$SID
    )
    # Function implementation
}
```

## 3. GUID Validation

### Using Test-IsValidGUID Function

This utility function `Test-IsValidGUID` would be part of the EguibarIT.HousekeepingPS module and is used for validating the format of a Globally Unique Identifier.

```powershell
function Get-ADObjectByGuid {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript(
            { Test-IsValidGUID -ObjectGUID $_ },
            ErrorMessage = 'GUID provided is not valid! Please check format.'
        )]
        [String]$ObjectGUID
    )
    # Function implementation
}
```

## 4. Validating Object Existence

This function checks if an Active Directory object exists, supporting various identity formats.

```powershell
function Test-ADObjectExists {

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Identity
    )

    try {

        # Determine identity type and look up object
        if (Test-IsValidDN -ObjectDN $Identity) {

            Get-ADObject -Identity $Identity -ErrorAction Stop | Out-Null

        } elseif (Test-IsValidSID -ObjectSid $Identity) {

            Get-ADObject -Identity $Identity -ErrorAction Stop | Out-Null

        } elseif (Test-IsValidGUID -ObjectGUID $Identity) {

            Get-ADObject -Identity $Identity -ErrorAction Stop | Out-Null

        } else {

            # Assume sAMAccountName
            $ADObject = Get-ADObject -Filter {sAMAccountName -eq $Identity} -ErrorAction SilentlyContinue

            if ($null -eq $ADObject) {
                return $false
            } #end if

        } #end if

        return $true

    } catch {
        Write-Warning -Message ("Error validating object existence for '{0}': {1}" -f $Identity, $_.Exception.Message)
        return $false
    } #end try-catch

} #end function Test-ADObjectExists
```

## 5. Converting Identity to SID

This function converts a given identity (DN, GUID, or sAMAccountName) to its Security Identifier (SID).

```powershell
function Convert-ADIdentityToSID {

    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Identity
    )

    try {

        if (Test-IsValidDN -ObjectDN $Identity) {

            $ADObject = Get-ADObject -Identity $Identity -Properties objectSid
            return $ADObject.objectSid.Value

        } elseif (Test-IsValidGUID -ObjectGUID $Identity) {

            $ADObject = Get-ADObject -Identity $Identity -Properties objectSid
            return $ADObject.objectSid.Value

        } else {

            # Assume sAMAccountName
            $ADObject = Get-ADObject -Filter {sAMAccountName -eq $Identity} -Properties objectSid

            if ($null -ne $ADObject) {

                return $ADObject.objectSid.Value

            } else {

                throw "Could not find object with sAMAccountName: $Identity"

            } #end if-else

        } #end if-elseif-else

    } catch {
        throw "Error converting identity to SID: $_"
    } #end try-catch

} #end function Convert-ADIdentityToSID
```

## 6. Working with Well-Known SIDs

Well-Known SIDs are predefined SIDs that represent common security principals in Active Directory.
The EguibarIT.HousekeepingPS module provides an ordered collection for these SIDs.
At module load time, these SIDs are initialized as `$Variables.WellKnownSIDs` and can be referenced in your scripts.
This is the preferred way to work with well-known SIDs in the module.
You can access the well-known SIDs using the `$Variables.WellKnownSIDs` variable, which is a dictionary-like structure where keys are SIDs and values are their corresponding names.

For example, to search by Key to get Value use something like `$Variables.WellKnownSIDs['S-1-5-11']` will return SID `authenticated users` and to search by Value to get Key `$Variables.WellKnownSIDs.keys.where{$Variables.WellKnownSIDs[$_] -eq 'authenticated users'}` will return the SID key for `S-1-5-11`.

```powershell
# Reference well-known SIDs from the module's enumeration
$DomainAdminsSID = $Variables.WellKnownSIDs.keys.where{$Variables.WellKnownSIDs[$_] -eq 'Domain Admins'}
$EnterpriseAdminsSID = $Variables.WellKnownSIDs.keys.where{$Variables.WellKnownSIDs[$_] -eq 'Enterprise Admins'}

# Validate against specific SID patterns
function Test-IsAdminSid {
    param([String]$SID)

    if (-not (Test-IsValidSID -ObjectSid $SID)) {
        return $false
    } #end if

    # Check if SID is a domain admin or enterprise admin SID
    $DomainSidPattern = '^S-1-5-21-\d+-\d+-\d+-512$'
    $EnterpriseSidPattern = '^S-1-5-21-\d+-\d+-\d+-519$'

    return ($SID -match $DomainSidPattern) -or ($SID -match $EnterpriseSidPattern)
} #end function
```
