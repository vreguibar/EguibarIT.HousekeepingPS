function Get-AdObjectType {
    <#
    .SYNOPSIS
        This function retrieves the type of an Active Directory object based on the provided identity.

    .DESCRIPTION
        The Get-AdObjectType function determines the type of an Active Directory object based on the given identity.
        It supports various object types, including AD users, computers, and groups. The function provides verbose output.

    .PARAMETER Identity
        Specifies the identity of the Active Directory object. This parameter is mandatory.

        Possible values are:
          ADAccount object
          ADComputer object
          ADGroup object
          ADOrganizationalUnit object
          String representing DistinguishedName
          String representing SID
          String representing samAccountName


    .EXAMPLE
        Get-AdObjectType -Identity "davader"
        Retrieves the type of the Active Directory object with the SamAccountName "davader".

    .EXAMPLE
        Get-AdObjectType -Identity "CN=davade,OU=Users,OU=BAAD,OU=Sites,DC=EguibarIT,DC=local"
        Retrieves the type of the Active Directory object with the
        DistinguishedName "CN=davade,OU=Users,OU=BAAD,OU=Sites,DC=EguibarIT,DC=local".

    .EXAMPLE
        Get-AdObjectType -Identity "S-1-5-21-3484526001-1877030748-1169500100-1646"
        Retrieves the type of the Active Directory object with the
        SID "S-1-5-21-3484526001-1877030748-1169500100-1646".

    .EXAMPLE
        Get-AdObjectType -Identity "35b764b7-06df-4509-a54f-8fd4c26a0805"
        Retrieves the type of the Active Directory object with the GUID
        "35b764b7-06df-4509-a54f-8fd4c26a0805".

    .OUTPUTS
        Microsoft.ActiveDirectory.Management.ADAccount or
        Microsoft.ActiveDirectory.Management.ADComputer or
        Microsoft.ActiveDirectory.Management.AdGroup

    .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADUser                             | ActiveDirectory
                Get-ADGroup                            | ActiveDirectory
                Get-ADComputer                         | ActiveDirectory
                Add-ADOrganizationalUnit               | ActiveDirectory
                Set-AdObject                           | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Output                           | Microsoft.PowerShell.Utility
                Get-FunctionToDisplay                  | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Test-IsValidDN                         | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-CurrentErrorToDisplay              | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS

    .NOTES
        Version:         1.0
            DateModified:    08/Oct/2021
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar Information Technology S.L.
                http://www.eguibarit.com
    #>
    [CmdletBinding(SupportsShouldProcess = $false, ConfirmImpact = 'low')]

    Param (
        # Param1
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, ValueFromRemainingArguments = $false,
            HelpMessage = 'Identity of the object',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('ID', 'SamAccountName', 'DistinguishedName', 'DN', 'SID')]
        $Identity
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

        $ReturnValue = $null
        $newObject = $null

    } # End Begin Section

    Process {

        # Known Identities OR AD Objects
        If ($Identity -is [Microsoft.ActiveDirectory.Management.ADAccount]) {

            Write-Verbose -Message 'AD User Object'
            [Microsoft.ActiveDirectory.Management.ADAccount]$ReturnValue = $Identity

        } ElseIf ($Identity -is [Microsoft.ActiveDirectory.Management.ADComputer]) {

            Write-Verbose -Message 'AD Computer Object'
            [Microsoft.ActiveDirectory.Management.ADComputer]$ReturnValue = $Identity

        } ElseIf ($Identity -is [Microsoft.ActiveDirectory.Management.AdGroup]) {

            Write-Verbose -Message 'AD Group Object'
            [Microsoft.ActiveDirectory.Management.AdGroup]$ReturnValue = $Identity

        } ElseIf ($Identity -is [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit]) {

            Write-Verbose -Message 'Organizational Unit Object'
            [Microsoft.ActiveDirectory.Management.ADOrganizationalUnit]$ReturnValue = $Identity

        } else {
            Try {
                If ($Identity -is [String]) {
                    Write-Verbose -Message 'Simple String... Try to identify if SamAccountName DistinguishedName or SID as string.'

                    if (Test-IsValidDN -ObjectDN $Identity) {

                        Write-Verbose -Message 'Looking for DistinguishedName'

                        $newObject = Get-ADObject -Filter { DistinguishedName -eq $Identity }

                    } elseif (Test-IsValidSID -ObjectSID $Identity) {

                        Write-Verbose -Message 'Looking for ObjectSID'
                        $newObject = Get-ADObject -Filter { ObjectSID -eq $Identity }

                    } elseif (Test-IsValidGUID -ObjectGUID $Identity) {

                        Write-Verbose -Message 'Looking for ObjectGUID'
                        $newObject = Get-ADObject -Filter { ObjectGUID -eq $Identity }

                    } else {

                        Write-Verbose -Message 'Looking for SamAccountName'
                        $newObject = Get-ADObject -Filter { SamAccountName -eq $Identity }

                    } #end if-ElseIf-Else
                } #end If
            } catch {
                Get-CurrentErrorToDisplay -CurrentError $error[0]

                return $null
            } #end Try-Catch
        } #end If-ElseIf-Else





        If ($newObject -and (-not $ReturnValue)) {
            # once we have the object, lets get it from AD
            Switch ($newObject.ObjectClass) {

                'user' {
                    Write-Verbose -Message '#|-----> AD User Object from STRING'
                    [Microsoft.ActiveDirectory.Management.ADAccount]$ReturnValue = Get-ADUser -Identity $newObject
                }

                'group' {
                    Write-Verbose -Message '#|-----> AD Group Object from STRING'
                    [Microsoft.ActiveDirectory.Management.AdGroup]$ReturnValue = Get-ADGroup -Identity $newObject
                }

                'computer' {
                    Write-Verbose -Message '#|-----> AD Computer Object from STRING'
                    [Microsoft.ActiveDirectory.Management.ADComputer]$ReturnValue = Get-ADComputer -Identity $newObject
                }

                'organizationalUnit' {
                    Write-Verbose -Message '#|-----> AD Organizational Unit Object from STRING'
                    [Microsoft.ActiveDirectory.Management.organizationalUnit]$ReturnValue = Get-ADOrganizationalUnit -Identity $newObject
                }

                Default {
                    Write-Error -Message "#|-----> Unknown object type for identity: $Identity"

                    return $null
                }
            } # End Switch

        } #end If


    } # End Process Section

    End {
        Write-Verbose -Message "Function $($MyInvocation.InvocationName) finished getting AD object type."
        Write-Verbose -Message ''
        Write-Verbose -Message '-------------------------------------------------------------------------------'
        Write-Verbose -Message ''

        if ($null -ne $ReturnValue) {
            Write-Output $ReturnValue
        } #end If
    } # End End Section
} #end Function
