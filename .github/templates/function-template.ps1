<#
    .SYNOPSIS
        Brief description of function purpose.

    .DESCRIPTION
        Detailed description of what this function does.

    .PARAMETER Identity
        Specifies the identity of the target object. Can be a distinguished name (DN), GUID, SID, SAM account name.

    .EXAMPLE
        Get-Function -Identity 'CN=User1,OU=Users,DC=contoso,DC=com'

        Retrieves information about the specified AD object.

    .EXAMPLE
        'CN=User1,OU=Users,DC=contoso,DC=com' | Get-Function

        Pipes the identity to the function.

    .OUTPUTS
        [PSCustomObject] - Contains properties related to the target object.

    .NOTES
        Used Functions:
            Name                             ║ Module/Namespace
            ═════════════════════════════════╬══════════════════════════════
            Get-ADObject                     ║ ActiveDirectory
            Write-Verbose                    ║ Microsoft.PowerShell.Utility
            Get-FunctionDisplay              ║ EguibarIT.HousekeepingPS

    .NOTES
        Version:         1.0
        DateModified:    dd/MMM/yyyy
        LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibar.com
                        Eguibar IT
                        http://www.eguibarit.com

    .LINK
        https://github.com/vreguibar/EguibarIT.HousekeepingPS
#>

[CmdletBinding(
    SupportsShouldProcess = $true,
    ConfirmImpact = 'Medium',
    DefaultParameterSetName = 'Default'
)]
[OutputType([PSCustomObject])]

param (
    [Parameter(
        Mandatory = $true,
        ValueFromPipeline = $true,
        ValueFromPipelineByPropertyName = $true,
        Position = 0,
        HelpMessage = 'Identity of the target object (DN, GUID, SID, SAM account name)'
    )]
    [ValidateNotNullOrEmpty()]
    [Alias('DN', 'DistinguishedName')]
    [String[]]$Identity,

    [Parameter(Mandatory = $false)]
    [Switch]$PassThru
)

Begin {
    Set-StrictMode -Version Latest

    # Display function header if variables exist
    if ($null -ne $Variables -and
        $null -ne $Variables.HeaderHousekeeping) {

        $txt = ($Variables.HeaderHousekeeping -f
                (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
                (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt
    } #end If

    ##############################
    # Module imports
    Import-Module -Name ActiveDirectory -Force

    ##############################
    # Variables Definition

    [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)
    [hashtable]$SplatProgress = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)
    [int]$i = 0

    # Initialize a result object
    [PSCustomObject]$ResultObject = $null

} #end Begin

Process {

    ForEach ($CurrentIdentity in $Identity) {

        $SplatProgress = @{
            Activity        = 'Processing objects'
            Status          = ('Processing {0}' -f $CurrentIdentity)
            PercentComplete = (($i++ / $Identity.Count) * 100)
        }
        Write-Progress @SplatProgress

        try {
            Write-Verbose -Message ('Starting to process identity: {0}' -f $CurrentIdentity)

            # Get the AD object
            $Splat = @{
                Identity    = $CurrentIdentity
                Properties  = '*'
                ErrorAction = 'Stop'
            }

            if ($PSCmdlet.ShouldProcess($CurrentIdentity, 'Retrieve AD object')) {

                $ADObject = Get-ADObject @Splat

                # Create the result object
                $ResultObject = [PSCustomObject]@{
                    Identity = $CurrentIdentity
                    Object   = $ADObject
                    Success  = $true
                }

                Write-Verbose -Message ('Successfully processed: {0}' -f $CurrentIdentity)

            } #end if

        } catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {

            Write-Warning -Message ('Identity not found: {0}' -f $CurrentIdentity)
            $ResultObject = [PSCustomObject]@{
                Identity = $CurrentIdentity
                Object   = $null
                Success  = $false
                Error    = 'Identity not found'
            }

        } catch {

            Write-Error -Message ('Error processing {0}: {1}' -f $CurrentIdentity, $_.Exception.Message)
            $ResultObject = [PSCustomObject]@{
                Identity = $CurrentIdentity
                Object   = $null
                Success  = $false
                Error    = $_.Exception.Message
            }

        } #end try-catch

        # Output the result object if PassThru is specified
        if ($PassThru -and $ResultObject) {
            $ResultObject
        } #end if

    } #end ForEach

} #end Process

End {

    Write-Progress -Activity 'Processing objects' -Completed

    # Display function footer if variables exist
    if ($null -ne $Variables -and
        $null -ne $Variables.FooterHousekeeping) {

        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'processing XXXXX XXXXX & XXXXX.'
        )
        Write-Verbose -Message $txt
    } #end If
} #end End
