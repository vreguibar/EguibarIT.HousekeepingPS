Function Set-ServiceAccountHousekeeping {

    <#
        .SYNOPSIS
            Manages housekeeping tasks for service accounts within specified organizational units.

        .DESCRIPTION
            This function performs housekeeping operations on service accounts (SA) and managed service accounts
            (MSA) within a specified OU. It ensures that all accounts in the OU are members of a specified
            group and sets their 'employeeID' attribute to 'ServiceAccount'.

        .PARAMETER ServiceAccountDN
            Specifies the distinguished name of the organizational unit containing service accounts.

        .PARAMETER ServiceAccountGroupName
            Specifies the name of the group to which all service accounts from the specified OU should belong.

        .EXAMPLE
            Set-ServiceAccountHousekeeping -ServiceAccountDN 'OU=T0SA,OU=Service Accounts,OU=Admin,DC=EguibarIT,DC=local' -ServiceAccountGroupName 'SG_T0SA' -Verbose

            Adds all service accounts in the "OU=T0SA,OU=Service Accounts,OU=Admin,DC=EguibarIT,DC=local" OU to the "SG_T0SA" group and sets their 'employeeID' to 'ServiceAccount'.

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
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Service Account OU Distinguished Name.',
            Position = 0)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ })]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [String]
        $ServiceAccountDN,

        #Param2
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Name of the corresponding tier service account group (For tier0: SG_T0SA; for Tier1: SG_T1SA; for Tier2: SG_T2SA)',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        $ServiceAccountGroupName
    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -HashTable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        Import-MyModule ActiveDirectory

        ##############################
        # Variables Definition

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # Get the group of the corresponding service accounts
        $ServiceAccountGroup = Get-AdObjectType -Identity $PsBoundParameters['ServiceAccountGroupName']
        Write-Verbose -Message 'Get the group of the corresponding service accounts'

        # Define an empty array
        $Members = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)

    } #end Begin

    Process {
        # Fill the array with current group members
        Get-ADGroupMember -Identity $ServiceAccountGroup | ForEach-Object { [void]$Members.add($_) }

        # get all users and managed service accounts in the OU
        $Splat = @{
            Filter     = '*'
            SearchBase = $ServiceAccountDN
            Properties = 'SamAccountName', 'DistinguishedName', 'employeeType', 'employeeID'
        }
        $objects = @(Get-ADUser @Splat) + @(Get-ADServiceAccount @Splat)

        # Step 1: Add users/MSAs from the OU to the group if they are not already members
        # iterate all users & MSA/gMSA in the OU
        foreach ($obj in $objects) {

            # Add to group if not already a member
            if (-not $Members.Contains($obj.SamAccountName)) {

                if ($PSCmdlet.ShouldProcess($obj.Name, 'Add to group')) {

                    try {
                        Add-ADGroupMember -Identity $serviceAccountGroup -Members $obj
                    } catch {
                        Write-Error -Message ('Failed to add {0} to group: {1}' -f $obj.sAMAccountName, $_)
                    } #end Try-Catch

                } #end If
            } #end If

            # Update employeeType attribute if necessary
            if (
                ($obj.employeeID -ne 'ServiceAccount') -and
                ($PSCmdlet.ShouldProcess($obj.Name, 'Update employeeID attribute'))
            ) {

                try {
                    Set-ADObject -Identity $obj.DistinguishedName -Replace @{ employeeID = 'ServiceAccount' }
                } catch {
                    Write-Error -Message ('Failed to update employeeID for {0}: {1}' -f $obj.sAMAccountName, $_)
                } #end Try-Catch

            } #end If

        } #end ForEach

        # Step 2: Remove users that are in the group but do not belong to the OU
        # Iterate all members of the given group
        Foreach ($item in $Members) {
            # Check if group member has the corresponding object in the OU
            If (-not $objects.DistinguishedName.Contains($item)) {
                if ($PSCmdlet.ShouldProcess($Item, 'Remove from group')) {

                    try {
                        Remove-ADGroupMember -Identity $ServiceAccountGroup -Members $Item -Confirm:$false
                    } catch {
                        Write-Error -Message ('Failed to remove {0} from group: {1}' -f $Item, $_)
                    } #end Try-Catch

                } #end If ShouldProcess
            } #end If
        } #end Foreach

    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'setting Service Account housekeeping.'
        )
        Write-Verbose -Message $txt
    } #end End
}
