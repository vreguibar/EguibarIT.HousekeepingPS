Function New-SemiPrivilegedUser {
    <#
        .SYNOPSIS
            Creates a new Semi-Privileged user based on the AD Delegation Model.

        .DESCRIPTION
            This function creates a new Semi-Privileged user based on the Active Directory (AD) Delegation Model.
            It checks if the provided standard user exists, and if so, it creates a new Semi-Privileged user with the specified account type.
            It also sends notification emails and encrypted emails containing the password, if specified.

        .PARAMETER SamAccountName
            Identity of the user getting the new Admin Account (Semi-Privileged user).

        .PARAMETER EmailTo
            Valid Email of the target user. This address will be used to send information to her/him.

        .PARAMETER AccountType
            Must specify the account type. Valid values are T0 or T1 or T2

        .PARAMETER AdminUsersDN
            Distinguished Name of the container where the Admin Accounts are located.

        .PARAMETER From
            Valid Email of the sending user. This address will be used to send the information and for authenticate to the SMTP server.

        .PARAMETER CredentialUser
            User for authenticate to the SMTP server.

        .PARAMETER CredentialPassword
            Password for authenticate to the SMTP server. (User is E-mail address of sender)

        .PARAMETER SMTPserver
            SMTP server

        .PARAMETER SMTPport
            SMTP port

        .PARAMETER BodyTemplate
            Path to the body template file.

        .PARAMETER BodyImage
            Path to the attached image of body template.

        .PARAMETER PwdBodyTemplate
            Path to the body template file.

        .EXAMPLE
            New-SemiPrivilegedUser -samaccountname "JohnDoe" -accounttype "Admin" -emailto "john@example.com" -from "admin@example.com" -credentialUser "smtpuser" -credentialPassword "smtppassword" -smtphost "smtp.example.com" -smtpport 25 -bodytemplate "C:\Templates\NotificationEmailBody.html" -pwdbodytemplate "C:\Templates\PasswordEmailBody.html" -bodyimage "C:\Images\logo.png"

            This example creates a new Semi-Privileged user with the account type "Admin" for the standard user "JohnDoe".
            It sends notification emails to "john@example.com" using "admin@example.com" as the sender, and SMTP authentication credentials.
            It also specifies custom body templates for notification and encrypted password emails, and attaches an image to notification emails.

            .INPUTS
                String
                SecureString

            .OUTPUTS
                Microsoft.ActiveDirectory.Management.ADAccount

        .NOTES
            Used Functions:
                Name                                   | Module
                ---------------------------------------|--------------------------
                Get-ADUser                             | ActiveDirectory
                New-ADUser                             | ActiveDirectory
                Import-Module                          | Microsoft.PowerShell.Core
                Get-Content                            | Microsoft.PowerShell.Management
                Write-Verbose                          | Microsoft.PowerShell.Utility
                Write-Warning                          | Microsoft.PowerShell.Utility
                Get-Culture                            | Microsoft.PowerShell.Utility
                New-Object                             | Microsoft.PowerShell.Utility
                Get-FunctionDisplay                    | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-AdObjectType                       | EguibarIT.DelegationPS & EguibarIT.HousekeepingPS
                Get-RandomPassword                     | EguibarIT.HousekeepingPS
                Send-Email                             | EguibarIT.HousekeepingPS
        .NOTES
            Version:         1.0
            DateModified:    12/Sep/2022
            LasModifiedBy:   Vicente Rodriguez Eguibar
                vicente@eguibar.com
                Eguibar IT
                http://www.eguibarit.com
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium', DefaultParameterSetName = 'Default')]
    [OutputType([Microsoft.ActiveDirectory.Management.ADAccount])]

    Param (
        [Parameter( Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Identity of the user getting the new Admin Account (Semi-Privileged user).',
            Position = 0)]
        [Alias('Name', 'ID', 'Identity')]
        [ValidateNotNullOrEmpty()]
        $SamAccountName,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Must specify the account type. Valid values are T0 or T1 or T2',
            Position = 1)]
        [ValidateSet('T0', 'T1', 'T2')]
        [string]
        $AccountType,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Distinguished Name of the container where the Admin Accounts are located.',
            Position = 2)]
        [ValidateScript({ Test-IsValidDN -ObjectDN $_ }, ErrorMessage = 'DistinguishedName provided is not valid! Please Check.')]
        [Alias('DN', 'DistinguishedName', 'LDAPPath')]
        [string]
        $AdminUsersDN,


        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Valid Email of the target user. This address will be used to send information to her/him.',
            Position = 3)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [System.Net.Mail.MailAddress]
        $EmailTo,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Valid Email of the sending user. This address will be used to send the information and for authenticate to the SMTP server.',
            Position = 4)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [System.Net.Mail.MailAddress]
        $From,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'User for authenticate to the SMTP server.',
            Position = 5)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [string]
        $CredentialUser,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Password for authenticate to the SMTP server. (User is E-mail address of sender)',
            Position = 6)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [System.Security.SecureString]
        $CredentialPassword,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'SMTP server.',
            Position = 7)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [string]
        $SMTPserver,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'SMTP port number.',
            Position = 8)]
        [Parameter(ParameterSetName = 'DataByEmail')]
        [int]
        $SMTPport,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = 'Folder containing pictures for the Semi-Privileged user.',
            Position = 9)]
        [ValidateScript({
                if ( -Not ($_ | Test-Path) ) {
                    throw 'File or folder does not exist'
                }
                return $true
            })]
        [PSDefaultValue(Help = 'Default Value is "C:\PsScripts\"')]
        [System.IO.FileInfo]
        $PictureFolder = 'C:\PsScripts\'
    )

    Begin {
        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        # Verify the Active Directory module is loaded
        Import-MyModule 'ActiveDirectory' -Verbose:$false

        ##############################
        # Variables Definition

        [string] $PWD = Get-RandomPassword -PasswordLength 20 -Complexity 4
        [System.Security.SecureString] $newPassword = ConvertTo-SecureString -String $PWD -AsPlainText -Force
        [bool]$sendEmail = $false
        [bool]$sendPassword = $false
        [bool]$stdUserExist = $false

        # parameters variable for splatting CMDlets
        [hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)

        # Check if email address is provided
        if ($null -ne $EmailTo) {
            $sendEmail = $true
        } else {
            Write-Verbose -Message ('
                [PROCESS]
                        Semi-Privileged user will be created.
                        No EmailTo was provided, so no notification will be created nor sent to user..
                        Password must be set again manually.'
            )
            $sendEmail = $false
            $sendPassword = $false
        } #end If-Else

        $body = @"
                <!DOCTYPE html>
<html>
<head>
	<style>
/* Font Definitions */

/* Style Definitions */
html, body {
	font-size:14px;
	font-family:`"Roboto`",`"sans-serif`";
	color:#444;
	}
p, li {
	margin-right:0cm;
	margin-left:0cm;
	font-size:14px;
	font-family:`"Roboto`",`"sans-serif`";
	color:#444;}
h1, h2, h3, h4 {
	font-family: "Exo 2",sansserfi;
	color:#4678b4;
}
	</style>
</head>
<body>
	<div align=center>
		<table border=0 cellspacing=0 cellpadding=0 width=600 style='width:450.0pt'>
			<tr>
				<td>
					<img width=600 height=200 src="C:\Users\RODRIGUEZEGUIBARVice\OneDrive-EguibarIT\_Scripts\LabSetup\SourceDC\Modules\Picture1.jpg" />
				</td>
			</tr>
		</table>
	<br>
		<span>
		<table border=0 cellspacing=0 cellpadding=0 width=600 style='width:450.0pt'>
			<tr>
				<td style='padding:0cm 0cm 0cm 0cm'>
					<h2><b>Announcement:</b> Operational Change on Active Directory Semi-Privileged Access Account.</h2>
					<p>
						As part of our continued improvement plans in our Active Directory #@DomainName@#, a new <i>'Delegation Model'</i>
						is been implemented. This model will enforce a set of security guidelines that have been authorized by
						the <b>ISO Security Team</b>, approved by our <b>Change and Release Control Committee</b> and
						will be implemented and maintained by the <b>Infrastructure Management Teams</b>.
					</p>
					<p>
					The main objective of these changes is to implement a strict segregation of duties model. In
					Active Directory, this means that anyone who needs to manage Active Directory objects such as
					Create/Change/Delete users, groups, computers, etc., will require a separate account, with
					the corresponding delegated rights. These accounts are independent and not associated with your
					standard daily usage  domain account. Below there is brief description of privileged accounts
					in the new model.
					</p>
					<table border=1>
						<tr border=1 style='background:black;color:silver'>
							<th>
								Account
							</th>
							<th>
								Description
							</th>
						</tr>
						<tr>
							<td style='background:#ffcccc'>
								<br>
								SamAccountName_T0 &nbsp; &nbsp; &nbsp;
								<br>
							</td>
							<td>
								Reserved for specific restricted operational task.
								Mainly infrastructure related.
								Also known as "Administration area" and/or Tier0.<br>
							</td>
						</tr>
						<tr>
							<td style='background:#ccffcc'>
								<br>
								SamAccountName_T1 &nbsp; &nbsp; &nbsp;
								<br>
							</td>
							<td>
								Reserved for Servers and/or /Services administration.
								Also known as "Servers area" and/or Tier1.<br>
							</td>
						</tr>
						<tr>
							<td style='background:#adc6e5'>
								<br>
								SamAccountName_T2 &nbsp; &nbsp; &nbsp;
								<br>
							</td>
							<td>
								Reserved for standard User/Group/PC administration.
								Also known as "Sites area" and/or Tier0.<br>
							</td>
						</tr>
					</table>
					<br>
					<p>
					One of the main changes to Active Directory is to implement a strict separation of permissions
					and rights. This means that anyone who needs to manage Active Directory objects (Create/Change/Delete
					users, groups, computers, etc.) does needs a separate account having the corresponding rights.
					</p>
					<p>
					Based on your current identified role, a new administrative account has been automatically generated.
					This account has been generated based on your current UserID (also known as SamAccountName).
					</p>
					<br>
						<TABLE>
							<TR>
								<TD style='background:black;color:silver'>
									<br>
									Your new Semi-Privileged UserID is: &nbsp; &nbsp;
									<br><br>
								</TD>
								<TD style='background:silver'>
									<span style='font-size:11.0pt;font-family:"Verdana","sans-serif";color:darkblue'>
										&nbsp;#@UserID@#&nbsp;
									</span>
								</TD>
							</TR>
						</TABLE>
					<p>
					You will receive your password in a  separate communication.
					</p>
					<p>
					As these Administrative Accounts are considered <b>'Semi-Privileged Accounts'</b> the only authorized team to
					manage (create, reset, and remove) these accounts are the <b>Infrastructure Management Teams</b>. In the
					event of requiring any of the previously mentioned services, please open a service request ticket to the
					corresponding team.
					</p>
					<p>
					For additional details you can get more information in our site at
					<a href="http://www.DelegationModel.eu">
						EguibarIT Delegation Model.
					</a>
					</p>
					<p>
					We appreciate your cooperation and collaboration in helping securing our environment.
					</p>
					<p>Sincerely,</p>
					<p>
					Eguibar Information Technology S.L.
					</p>
				</td>
			</tr>
		</table>
	</span>
	</div>
	<br>
	<hr>
	<div align=center><font size='2' color='696969' face='arial'>This e-mail has been automatically generated by AD Delegation Model toolset</font></div>
</body>
</html>
"@

    } #end Begin

    Process {

        # Search for Non-Privileged user.
        $StdUser = Get-AdObjectType -Identity $PsBoundParameters['SamAccountName']

        # If exist, retrieve all corresponding properties.
        # Id does not exist, write a warning and exit script.
        if ($null -eq $StdUser) {
            Write-Error -Message ('
                [ERROR]
                        Standard User {0} does not exist.
                        Before creating a Semi-Privileged user, a standard user (Non-Privileged user) must exist.
                        Make sure a standard user exists before proceeding.' -f
                $PsBoundParameters['SamAccountName']
            )

            $stdUserExist = $false
            $sendEmail = $false
            $sendPassword = $false
        } else {
            Write-Verbose -Message ('
                [PROCESS]
                        Standard user (Non-Privileged user) found!
                        Proceeding to create the Semi-Privileged user.'
            )
            $stdUserExist = $true

            If ($StdUser.EmailAddress) {

                If (-Not ($PsBoundParameters['EmailTo'])) {
                    Write-Verbose -Message ('
                        [PROCESS]
                            EmailTo was not given, but found it on standard user.
                            Using this email as a recipient.'
                    )
                    $sendEmail = $true
                    $PsBoundParameters['EmailTo'] = $StdUser.EmailAddress
                } #end If
            } #end If
        } #end If-Else


        ################################################################################
        # Standard user (Non-Privileged user) exists. Create the Semi-Privileged user
        If ($stdUserExist) {

            $Splat = @{
                SamAccountName = $StdUser.SamAccountName
                AccountType    = $PSBoundParameters['AccountType']
                AdminUsersDN   = 'OU=Users,OU=Admin,DC=EguibarIT,DC=local'
                Password       = $newPassword
                PictureFolder  = $PictureFolder
            }
            $SemiPrivilegedUser = Set-SemiPrivilegedUser @Splat


            ################################################################################
            # Send Email notification
            if ($sendEmail) {

                # Find pattern within body text and replace it with new Semi-Privileged SamAccountName
                $body = $body -replace '#@UserID@#', $SemiPrivilegedUser.SamAccountName

                # Find pattern within body text and replace it with DNS Domain Name (FQDN)
                $body = $body -replace '#@DomainName@#', $Variables.DnsFqdn

                # Check if any image was passed
                If ($PsBoundParameters['BodyImage']) {
                    # Load the image file into a System.Drawing.Bitmap object
                    $bmp = [System.Drawing.Bitmap]::FromFile($PsBoundParameters['BodyImage'])

                    try {
                        # Save the Bitmap to the stream in BMP format
                        $bmp.Save($stream, [System.Drawing.Imaging.ImageFormat]::Bmp)
                        # Reset the stream position to the beginning
                        $stream.Position = 0

                        # Prepare the attachment using a memory stream
                        $attachment = [System.Net.Mail.Attachment]::New($stream, [System.IO.Path]::GetFileName($PsBoundParameters['BodyImage']), 'image/bmp')
                    } finally {
                        # Ensure that the bitmap is disposed of to free resources
                        $bmp.Dispose()
                    } #end Try-Finally
                } #end If

                # Compile the eMail
                $Splat = @{
                    Recipient      = $PsBoundParameters['EmailTo']
                    Subject        = 'New Semi-Privileged account based on the AD Delegation Model'
                    Body           = $body
                    From           = 'DelegationModel@EguibarIT.com'
                    ClientId       = '67b0de82-6ee8-4720-b54e-c3932b7e1ff5'
                    TenantId       = '80be540f-1de9-43fe-aab7-da6232ba820f'
                    CertThumbprint = 'C5EF34A09BEAE5C75D904DA8DD54825D0787B60C'
                }

                If ($PSBoundParameters.ContainsKey('Attachment')) {
                    $Splat.Add('Attachment', $PsBoundParameters['Attachment'])
                } #end If

                Try {
                    # Send the email
                    #Send-NotificationEmail @Splat
                    Send-NotificationGraphEmail @Splat
                    Write-Verbose -Message ('
                        [PROCESS]
                            Notification email sent successfully.'
                    )
                } catch {
                    Write-Warning -Message ('
                        [ERROR]
                            Notification email could not be sent.'
                    )
                    $sendPassword = $false
                    throw
                } #end Try-Catch


            } else {
                Write-Verbose -Message ('
                    [PROCESS]
                        Semi-Privileged user created.
                        No notification will be created nor email will be sent.
                        Password must be set again manually.'
                )

                $sendEmail = $false
                $sendPassword = $false
            } #end If


            ################################################################################
            # Send encrypted Email containing password


        } #end If

    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'creating/modifying Semi-Privileged user.'
        )
        Write-Verbose -Message $txt
    } #end End
}
