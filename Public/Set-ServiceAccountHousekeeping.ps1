Function Set-ServiceAccountHousekeeping {
    <#
        .SYNOPSIS
            Manages housekeeping tasks for service accounts within specified organizational units.

        .DESCRIPTION
            This function performs housekeeping operations on service accounts (SA) and managed service accounts
            (MSA) within a specified OU. It ensures that all accounts in the OU are members of a specified
            group and sets their 'employeeType' attribute to 'ServiceAccount'.

        .PARAMETER ServiceAccountDN
            Specifies the distinguished name of the organizational unit containing service accounts.

        .PARAMETER ServiceAccountGroupName
            Specifies the name of the group to which all service accounts from the specified OU should belong.

        .EXAMPLE
            Set-ServiceAccountHousekeeping -ServiceAccountDN "OU=ServiceAccounts,DC=domain,DC=com" -ServiceAccountGroupName "SG_T1SA"
            Adds all service accounts in the "OU=ServiceAccounts,DC=domain,DC=com" OU to the "SG_T1SA" group and sets their 'employeeType' to 'ServiceAccount'.

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADGroup                            | ActiveDirectory
                Get-ADGroupMember                      | ActiveDirectory
                Add-ADGroupMember                      | ActiveDirectory
                Set-AdObject                           | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Get-FunctionToDisplay                  | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Test-IsValidDN                         | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-AdObjectType                       | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    20/Jul/2017
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    [OutputType([void])]

    Param (
        #Param1
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Service Account OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $ServiceAccountDN,

        #Param2
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Name of the corresponding tier service account group (For tier0: SG_T0SA; for Tier1: SG_T1SA; for Tier2: SG_T2SA)',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [String]
        $ServiceAccountGroupName
    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        # Verify the Active Directory module is loaded
        if (-not (Get-Module -Name ActiveDirectory)) {
            Import-Module ActiveDirectory -Force -Verbose:$false
        } #end If

        ##############################
        # Variables Definition

        # Get the group of the corresponding service accounts
        $ServiceAccountGroup = Get-ADGroup -Identity $PsBoundParameters['ServiceAccountGroupName']
        Write-Verbose -Message 'Get the group of the corresponding service accounts'

        # Define an empty array
        $Members = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

        # Get the group
        $ServiceAccountGroupName = Get-AdObjectType -Identity $PsBoundParameters['ServiceAccountGroupName']

    } #end Begin

    Process {
        # Fill the array with current group members
        Get-ADGroupMember -Identity $ServiceAccountGroup | ForEach-Object { $Members.add($_) }

        # get all users and managed service accounts in the OU
        $objects = @(Get-ADUser -Filter * -SearchBase $ServiceAccountDN) + @(Get-ADServiceAccount -Filter * -SearchBase $ServiceAccountDN)


        # iterate all users & MSA/gMSA in the OU
        foreach ($obj in $objects) {
            if ($members -notcontains $obj.sAMAccountName) {
                if ($PSCmdlet.ShouldProcess($obj.Name, 'Add to group')) {
                    Add-ADGroupMember -Identity $serviceAccountGroup -Members $obj -WhatIf:$false
                } #end If
            } #end If
            if ($PSCmdlet.ShouldProcess($obj.Name, 'Update employeeType attribute')) {
                Set-ADObject -Identity $obj.DistinguishedName -Replace @{ employeeType = 'ServiceAccount' } -WhatIf:$false
            } #end If
        } #end ForEach

    } #end Process

    End {
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished setting Service Account housekeeping."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''
    } #end End
}
