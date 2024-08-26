function Clear-AdminCount {
    <#
        .SYNOPSIS
            Clears the 'adminCount' attribute of an Active Directory object and resets object security inheritance.

        .DESCRIPTION
            This function retrieves an AD object by its SamAccountName, clears the 'adminCount' attribute,
            and ensures that security inheritance is reset. It can handle users, groups, and potentially other object types
            that can have security permissions.

        .PARAMETER SamAccountName
            The SamAccountName of the AD object to modify.

        .EXAMPLE
            Clear-AdAdminCount -SamAccountName "jdoe"

            Description
            -----------
            Clears the 'adminCount' attribute for the AD object with SamAccountName 'jdoe' and ensures that inheritance of security permissions is enabled.

        .OUTPUTS
            String
            Outputs a string indicating the operation result.

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADObject                           | ActiveDirectory
                Set-ADObject                           | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Error                            | Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.1
            DateModified:    08/Feb/2024
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>
    [CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = 'Low')]
    [OutputType([string])]

    Param(

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True,
            ValueFromRemainingArguments = $false,
            HelpMessage = 'The SamAccountName of the AD object to modify.',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('IdentityReference', 'Identity', 'Account')]
        [string]
        $SamAccountName

    )

    Begin {

        $txt = ($constants.Header -f
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

        $adObject = $null
        $dnPath = $null
        $directoryEntry = $null
        $acl = $null
        [string]$result = $null

    } #end Begin

    Process {
        try {
            # Get the AD Object
            $adObject = Get-ADObject -Filter { SamAccountName -eq $SamAccountName } -Properties adminCount

            if ($adObject) {
                # Confirm action before proceeding
                if ($Force -or $PSCmdlet.ShouldProcess($adObject.DistinguishedName, 'Clear adminCount and reset inheritance')) {

                    # Clear adminCount attribute
                    Set-ADObject -Identity $adObject -Clear adminCount -WhatIf:$WhatIfPreference

                    # Get the distinguished name
                    $dnPath = 'LDAP://{0}' -f $adObject.DistinguishedName
                    $directoryEntry = New-Object System.DirectoryServices.DirectoryEntry $dnPath

                    # Modify security settings to allow inheritance
                    $acl = $directoryEntry.ObjectSecurity
                    if ($acl.AreAccessRulesProtected) {
                        $acl.SetAccessRuleProtection($false, $true)
                        $directoryEntry.CommitChanges()
                    } #end if

                    $result = 'Object: {0} - Updated permissions, inheritance reset.' -f $adObject.DistinguishedName
                    Write-Verbose -Message $result
                }#end If
            } else {
                $result = 'AD object not found.'
                Write-Verbose -Message $result
            } #end If-Else
        } catch {
            Write-Error -Message "An error occurred: $_"
        } #end Try-Catch
    } #end Process

    End {
        $txt = ($Constants.Footer -f $MyInvocation.InvocationName,
            'processing AdminCount & Permissions (Private Function).'
        )
        Write-Verbose -Message $txt

        return $result
    } #end End
}
