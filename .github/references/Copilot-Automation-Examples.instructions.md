# GitHub Copilot Automation Examples

This document provides real-world examples showing how GitHub Copilot should assist with PowerShell function development for the `EguibarIT.HousekeepingPS` module, demonstrating expected user prompts and Copilot's generated responses.

## Table of Contents

1. Function Creation Examples
    1.1 Creating a Delegation Function
    1.2 Creating a New AD User Function
2. Related Documentation

## 1. Function Creation Examples

### 1.1 Creating a Delegation Function

**User Prompt:**

```
Create a function named Set-AdAclDelegateHomeFolder that delegates permissions to a security group to manage user home folders.
```

**Expected Copilot Response:**

```powershell
function Set-AdAclDelegateHomeFolder {
    <#
        .SYNOPSIS
            Grants a security group the permissions to manage user home folders.

        .DESCRIPTION
            The Set-AdAclDelegateHomeFolder function grants a security group the necessary permissions to manage user home folders.
            It sets up the appropriate NTFS permissions on the specified path.

        .PARAMETER Group
            The identity of the group that will receive permissions.

        .PARAMETER Path
            The file system path where the home folders are stored.

        .EXAMPLE
            Set-AdAclDelegateHomeFolder -Group "SG_HomeFolderAdmins" -Path "\\server\HomeShare"

            Grants the SG_HomeFolderAdmins group permission to manage user home folders in the \\server\HomeShare path.

        .INPUTS
            [String]
            You can pipe the Group parameter identity to this function.

        .OUTPUTS
            [System.Boolean]
            Returns True if successful, otherwise False.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                Grant-NTFSPermission             ║ EguibarIT.HousekeepingPS
                Write-Verbose                    ║ Microsoft.PowerShell.Utility
                Write-Error                      ║ Microsoft.PowerShell.Utility
                Get-Date                         ║ Microsoft.PowerShell.Utility
                Test-Path                        ║ Microsoft.PowerShell.Management
                Get-FunctionDisplay              ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    27/May/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS/blob/main/Functions/Set-AdAclDelegateHomeFolder.ps1

        .COMPONENT
            Active Directory Delegation

        .ROLE
            Tier 1 Administrator

        .FUNCTIONALITY
            Manages file system permissions for user home folders.
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([System.Boolean])]

    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            Position = 0,
            HelpMessage = 'The identity of the group that will receive permissions'
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('Identity', 'GroupName')]
        [String]
        $Group,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            Position = 1,
            HelpMessage = 'File system path where the home folders are stored'
        )]
        [ValidateScript({
            if (-not (Test-Path -Path $_ -PathType Container)) {
                throw ('Directory not found: {0}' -f $_)
            }
            return $true
        })]
        [String]
        $Path
    )

    Begin {
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Header) {

            $txt = ($Variables.Header -f
                (Get-Date).ToString('dd/MMM/yyyy'),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Variables Definition
        [boolean]$Result = $false

    } #end Begin

    Process {

        try {

            if ($PSCmdlet.ShouldProcess($Path, ('Grant {0} NTFS permissions to manage home folders' -f $Group))) {

                Write-Verbose -Message ('Granting NTFS permissions to {0} on {1}' -f $Group, $Path)

                # Grant permissions using the module's existing function
                $Result = Grant-NTFSPermission -Path $Path -Identity $Group -Permission 'FullControl' -ApplyTo 'ThisFolderSubfoldersAndFiles'

                if ($Result) {

                    Write-Verbose -Message ('Successfully granted permissions to {0}' -f $Group)
                } else {

                    Write-Warning -Message ('Failed to grant permissions to {0}' -f $Group)

                } #end if-else

            } #end if

        } catch {

            Write-Error -Message ('Error granting permissions: {0}' -f $_.Exception.Message)
            $Result = $false

        } #end try-catch
    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Footer) {

            $txt = ($Variables.Footer -f $MyInvocation.InvocationName,
                'processing NTFS permissions for home folders.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $Result
    } #end End
} #end function Set-AdAclDelegateHomeFolder
```

### Example 1.2: Creating a New AD User Function

**User Prompt:**

```
Review this function for adherence to our coding standards:

function New-CustomADUser {
    param([string]$Name, [string]$Path)

    New-ADUser -Name $Name -Path $Path -Enabled $true
    Write-Host "User created"
}
```

**Expected Copilot Response:**

The function `New-CustomADUser` doesn't comply with our coding standards. Here are the issues and recommended improvements:

**Issues:**

1. Missing comment-based help
2. Missing CmdletBinding attribute
3. Missing parameter validation and attributes
4. Missing Begin/Process/End blocks
5. Using Write-Host instead of Write-Verbose
6. Missing error handling
7. No return value
8. Missing pipeline support
9. Missing ShouldProcess for state-changing operation

**Improved Function:**

```powershell
function New-CustomADUser {

    <#
        .SYNOPSIS
            Creates a new Active Directory user.

        .DESCRIPTION
            The New-CustomADUser function creates a new Active Directory user with the specified name
            in the specified organizational unit path.

        .PARAMETER Name
            The name of the new user.

        .PARAMETER Path
            The distinguished name of the organizational unit where the user will be created.

        .EXAMPLE
            New-CustomADUser -Name "John Doe" -Path "OU=Users,DC=contoso,DC=com"

            Creates a new enabled user named "John Doe" in the specified OU.

        .INPUTS
            None. You cannot pipe objects to New-CustomADUser.

        .OUTPUTS
            [Microsoft.ActiveDirectory.Management.ADUser]
            Returns the newly created AD user object.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                New-ADUser                       ║ ActiveDirectory
                Write-Verbose                    ║ Microsoft.PowerShell.Utility
                Write-Error                      ║ Microsoft.PowerShell.Utility
                Get-Date                         ║ Microsoft.PowerShell.Utility
                Test-IsValidDN                   ║ EguibarIT.HousekeepingPS
                Get-FunctionDisplay              ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    27/May/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
        [https://docs.microsoft.com/en-us/powershell/module/activedirectory/new-aduser](https://docs.microsoft.com/en-us/powershell/module/activedirectory/new-aduser)

    .COMPONENT
        User Management

    .ROLE
        Tier 2 Administrator

    .FUNCTIONALITY
        Provisions new Active Directory user accounts.
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([Microsoft.ActiveDirectory.Management.ADUser])]

    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'The name of the new user',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern\('^\[a\-zA\-Z0\-9\.\_\-\]\+</span>')]
        [String]
        $Name,

        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'The distinguished name of the organizational unit where the user will be created'
            Position = 1)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'Path provided is not a valid distinguished name!'
        )]
        [String]
        $Path
    )

    Begin {
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Header) {

            $txt = ($Variables.Header -f
            (Get-Date).ToString('dd/MMM/yyyy'),
                $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module imports

        Import-MyModule -Name ActiveDirectory -Force -Verbose:$false

        ##############################
        # Variables Definition

    } #end Begin

    Process {

        try {

            if ($PSCmdlet.ShouldProcess($Name, "Create new AD user")) {

                Write-Verbose -Message ('Creating new AD user {0} in {1}' -f $Name, $Path)

                $Splat = @{
                    Name        = $Name
                    Path        = $Path
                    Enabled     = $true
                    ErrorAction = 'Stop'
                }
                $NewUser = New-ADUser @Splat -PassThru

                Write-Verbose -Message ('User {0} created successfully' -f $Name)

                return $NewUser
            } #end if

        } catch {
            Write-Error -Message ('Failed to create user {0}: {1}' -f $Name, $_.Exception.Message)
        } #end try-catch
    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Footer) {

            $txt = ($Variables.Footer -f $MyInvocation.InvocationName,
                'processing new custom AD user.'
            )
            Write-Verbose -Message $txt
        } #end If
    } #end End
} #end function New-CustomADUser
```

These changes bring the function in line with our coding standards, including proper documentation, error handling, parameter validation, and adherence to PowerShell best practices.

### Example 1.3: Creating a validation function

**User Prompt:**

```
Create a function named Test-IsInProtectedOU that checks if an AD object is in a protected OU that should not be modified.
```

**Expected Copilot Response:**

```powershell
function Test-IsInProtectedOU {

    <#
        .SYNOPSIS
            Checks if an AD object is located in a protected OU.

        .DESCRIPTION
            The Test-IsInProtectedOU function verifies whether an AD object resides in a protected OU
            that should not be modified or requires special permissions to modify.

        .PARAMETER Identity
            Distinguished Name (DN) of the AD object to check.

        .PARAMETER ProtectedOUs
            An array of distinguished names of protected OUs. If not provided, a default list is used.

        .EXAMPLE
            Test-IsInProtectedOU -Identity "CN=Server01,OU=Domain Controllers,DC=contoso,DC=com"

            Returns True because the Domain Controllers OU is protected.

        .EXAMPLE
            "CN=User1,OU=Users,DC=contoso,DC=com" | Test-IsInProtectedOU

            Returns False if the Users OU is not in the protected list.

        .INPUTS
            [String]
            You can pipe the Identity parameter to this function.

        .OUTPUTS
            [System.Boolean]
            Returns True if the object is in a protected OU, otherwise False.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                Test-IsValidDN                   ║ EguibarIT.HousekeepingPS
                Write-Verbose                    ║ Microsoft.PowerShell.Utility
                Write-Error                      ║ Microsoft.PowerShell.Utility
                Get-Date                         ║ Microsoft.PowerShell.Utility

        .NOTES
            Version:         1.0
            DateModified:    27/May/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS/blob/main/Functions/Test-IsInProtectedOU.ps1

        .COMPONENT
            Active Directory

        .ROLE
            Administrator

        .FUNCTIONALITY
            Security Validation
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Medium'
    )]
    [OutputType([System.Boolean])]

    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Distinguished Name of the AD object to check'
            Position = 0)]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'Distinguished Name provided is not valid! Please check.'
        )]
        [Alias('DN', 'DistinguishedName')]
        [String]
        $Identity,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'List of protected OU distinguished names'
            Position = 1)]
        [String[]]
        $ProtectedOUs
    )

    Begin {
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Header) {

            $txt = ($Variables.Header -f
            (Get-Date).ToString('dd/MMM/yyyy'),
                $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module imports


        ##############################
        # Variables Definition

        # Default list of protected OUs
        if (-not $ProtectedOUs) {
            $ProtectedOUs = @(
                'OU=Domain Controllers,{0}',
                'CN=Computers,{0}',
                'CN=Users,{0}',
                'CN=System,{0}'
            )

            # Get the domain component part of the Identity
            if (Test-IsValidDN -ObjectDN $Identity) {
                $DomainDN = $Identity.Substring($Identity.IndexOf('DC='))

                # Apply domain to each protected OU template
                $ProtectedOUs = $ProtectedOUs | ForEach-Object {
                    $_ -f $DomainDN
                }
            }
        }

        Write-Verbose -Message ('Testing if {0} is in a protected OU' -f $Identity)
        Write-Verbose -Message ('Protected OUs: {0}' -f ($ProtectedOUs -join ', '))
    } #end Begin

    Process {

        try {

            # Check if the object is directly in a protected OU
            foreach ($ProtectedOU in $ProtectedOUs) {

                if ($Identity -eq $ProtectedOU) {

                    Write-Verbose -Message ('Object is a protected OU: {0}' -f $Identity)
                    return $true

                } #end if

                if ($Identity.EndsWith(",$ProtectedOU")) {

                    Write-Verbose -Message ('Object is in protected OU: {0}' -f $ProtectedOU)
                    return $true

                } #end if
            } #end foreach

            # Not in protected OU
            Write-Verbose -Message ('Object is not in a protected OU: {0}' -f $Identity)
            return $false

        } catch {

            Write-Error -Message ('Error checking protected OU status: {0}' -f $_.Exception.Message)
            return $false

        } #end try-catch
    } #end Process

    End {
        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Footer) {

            $txt = ($Variables.Footer -f $MyInvocation.InvocationName,
                'testing objects in protected OU.'
            )
            Write-Verbose -Message $txt
        } #end If
    } #end End
} #end function Test-IsInProtectedOU
```

### Example 1.4: Adding performance optimization to existing function

**User Prompt:**

```
Optimize this function for large AD environments with 100,000+ objects:

function Get-AllAdUsers {
    [CmdletBinding()]
    param()

    return Get-ADUser -Filter *
}
```

**Expected Copilot Response:**

```powershell
function Get-AllAdUsers {

    <#
        .SYNOPSIS
            Gets all AD users with optimized performance for large environments.

        .DESCRIPTION
            The Get-AllAdUsers function retrieves all Active Directory users with pagination
            and proper resource management for environments with 100,000+ user objects.

        .PARAMETER SearchBase
            The distinguished name of the search base. If not specified, uses the domain root.

        .PARAMETER Properties
            List of properties to retrieve for each user. Default is basic properties.

        .PARAMETER PageSize
            Number of objects to retrieve in each page. Default is 1000.

        .EXAMPLE
            Get-AllAdUsers

            Retrieves all users in the domain with basic properties.

        .EXAMPLE
            Get-AllAdUsers -SearchBase "OU=Users,DC=contoso,DC=com" -Properties DisplayName,Department,Title

            Retrieves all users in the specified OU with the requested properties.

        .INPUTS
            None. You cannot pipe objects to Get-AllAdUsers.

        .OUTPUTS
            [PSCustomObject]
            Returns custom objects with user properties.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                Write-Verbose                    ║ Microsoft.PowerShell.Utility
                Write-Progress                   ║ Microsoft.PowerShell.Utility

        .NOTES
            Version:         1.0
            DateModified:    27/May/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                            vicente@eguibar.com
                            Eguibar IT
                            http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS/blob/main/Functions/Get-AllAdUsers.ps1

        .COMPONENT
            Active Directory

        .ROLE
            Reader

        .FUNCTIONALITY
            User Management
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'Low'
    )]
    [OutputType([PSCustomObject[]])]

    param(
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'AD path to search for users'
        )]
        [ValidateScript(
            { Test-IsValidDN -ObjectDN $_ },
            ErrorMessage = 'SearchBase provided is not a valid DN! Please check.'
        )]
        [String]
        $SearchBase,

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'User properties to retrieve'
        )]
        [PSDefaultValue(Help = 'Default Value is "SamAccountName, DisplayName, Enabled, UserPrincipalName, DistinguishedName"',
            Value = @('SamAccountName', 'DisplayName', 'Enabled', 'UserPrincipalName', 'DistinguishedName')
        )]
        [String[]]
        $Properties = @('SamAccountName', 'DisplayName', 'Enabled', 'UserPrincipalName', 'DistinguishedName'),

        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            ValueFromPipelineByPropertyName = $false,
            HelpMessage = 'Number of objects per page'
        )]
        [PSDefaultValue(Help = 'Default Value is "1000',
            Value = 1000
        )]
        [ValidateRange(100, 5000)]
        [Int]
        $PageSize = 1000
    )

    Begin {
        Set-StrictMode -Version Latest

        # Display function header if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Header) {

            $txt = ($Variables.Header -f
                (Get-Date).ToString('dd/MMM/yyyy'),
                $MyInvocation.Mycommand,
                (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
            )
            Write-Verbose -Message $txt
        } #end If

        ##############################
        # Module imports

        ##############################
        # Variables Definition

        # Get domain if SearchBase not specified
        if (-not $SearchBase) {

            try {

                $Domain = Get-ADDomain -Current LoggedOnUser -ErrorAction Stop
                $SearchBase = $Domain.DistinguishedName

            } catch {

                throw "Failed to determine domain: $_"

            } #end try-catch

        } #end if

        Write-Verbose -Message ('Retrieving users from {0} with page size {1}' -f $SearchBase, $PageSize)
        Write-Verbose -Message ('Properties to retrieve: {0}' -f ($Properties -join ', '))

        # Use DirectorySearcher for optimal performance
        $Searcher = [System.DirectoryServices.DirectorySearcher]::new()
        $Searcher.SearchRoot = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$SearchBase")
        $Searcher.PageSize = $PageSize
        $Searcher.Filter = "(&(objectCategory=person)(objectClass=user))"
        $Searcher.SearchScope = "Subtree"

        # Add properties to retrieve
        foreach ($Prop in $Properties) {

            [void]$Searcher.PropertiesToLoad.Add($Prop.ToLower())

        } #end fi

        # Add required properties if not already included
        if (-not $Properties.Contains('distinguishedName')) {

            [void]$Searcher.PropertiesToLoad.Add('distinguishedName')

        } #end if

        # Initialize results array with appropriate capacity
        $Results = [System.Collections.Generic.List[PSObject]]::new(10000)

        # Initialize counters for progress
        $TotalUsers = 0
        $ProcessedUsers = 0

    } #end Begin

    Process {

        try {

            # Count total number of users for progress reporting (optimized query)
            $CountSearcher =[System.DirectoryServices.DirectorySearcher]::new()
            $CountSearcher.SearchRoot = [System.DirectoryServices.DirectoryEntry]::new("LDAP://$SearchBase")
            $CountSearcher.Filter = "(&(objectCategory=person)(objectClass=user))"
            $CountSearcher.SearchScope = "Subtree"
            [void]$CountSearcher.PropertiesToLoad.Add('distinguishedName')
            $TotalUsers = $CountSearcher.FindAll().Count
            $CountSearcher.Dispose()

            Write-Verbose -Message ('Found {0} users. Beginning retrieval...' -f $TotalUsers)

            # Perform the paged search
            $PageNumber = 0
            $PagedResults = $Searcher.FindAll()

            foreach ($Entry in $PagedResults) {

                $ProcessedUsers++
                $PageNumber = [Math]::Floor($ProcessedUsers / $PageSize) + 1

                # Report progress every 100 users
                if ($ProcessedUsers % 100 -eq 0) {

                    $PercentComplete = [Math]::Min(100, ($ProcessedUsers / $TotalUsers * 100))

                    $SplatProgress = @{
                        Activity        = 'Retrieving AD users'
                        Status          = ('Processing page {0} - {1:N0} of {2:N0} users' -f $PageNumber, $ProcessedUsers, $TotalUsers)
                        PercentComplete = $PercentComplete
                    }
                    Write-Progress @SplatProgress
                } #end if

                # Create custom object for each user
                $UserObject = [PSCustomObject]@{}

                # Add properties to the object
                foreach ($Prop in $Searcher.PropertiesToLoad) {

                    if ($Entry.Properties[$Prop].Count -gt 0) {

                        # Handle multi-valued and single-valued properties
                        if ($Entry.Properties[$Prop].Count -eq 1) {

                            $UserObject | Add-Member -MemberType NoteProperty -Name $Prop -Value $Entry.Properties[$Prop][0]

                        } else {

                            $UserObject | Add-Member -MemberType NoteProperty -Name $Prop -Value $Entry.Properties[$Prop]

                        } #end if-else

                    } else {

                        $UserObject | Add-Member -MemberType NoteProperty -Name $Prop -Value $null

                    } #end if-else
                } #end foreach

                # Add to results collection
                [void]$Results.Add($UserObject)
            } #end foreach

            # Clean up resources
            $PagedResults.Dispose()

        } catch {

            Write-Error -Message ('Error retrieving AD users: {0}' -f $_.Exception.Message)

        } #end try-catch

    } #end Process

    End {
        # Clean up resources
        $Searcher.Dispose()

        # Complete the progress bar
        Write-Progress -Activity 'Retrieving AD users' -Completed

        Write-Verbose -Message ('Retrieved {0} users' -f $Results.Count)

        # Display function footer if variables exist
        if ($null -ne $Variables -and
            $null -ne $Variables.Footer) {

            $txt = ($Variables.Footer -f $MyInvocation.InvocationName,
                'retriving all users with specified properties.'
            )
            Write-Verbose -Message $txt
        } #end If

        return $Results
    } #end End
} #end function Get-AllAdUsers
```

These changes bring the function in line with our coding standards, including proper documentation, error handling, parameter validation, and adherence to PowerShell best practices.
