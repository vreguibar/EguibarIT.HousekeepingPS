function Send-NotificationEmail {
    param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Email address of the recipient (to whom) of the email.',
            Position = 0)]
        [ValidateScript({ Test-EmailAddress -EmailAddress $_ })]
        [ValidateNotNullOrEmpty()]
        [Alias('Recipient')]
        [string]
        $To,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Subject of the email.',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Subject,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Body (content) of the email.',
            Position = 2)]
        [string]
        $Body,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'FQDN or IP Address of the SMTP to be used for sending this email.',
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]
        $SmtpServer,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'SMTP port to be used for sending this email.',
            Position = 4)]
        [ValidateNotNullOrEmpty()]
        [int]
        $SmtpPort,

        [Parameter( Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'The username for SMTP authentication.',
            Position = 5)]
        [string]
        $Username,

        [Parameter( Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'The password for SMTP authentication. This should be provided securely as [System.Security.SecureString].',
            Position = 6)]
        [System.Security.SecureString]
        $Password,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Path to any required attachment.',
            Position = 7)]
        [string]
        $AttachmentPath
    )

    Begin {

        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        ##############################
        # Variables Definition

        $emailParams = @{
            Recipient  = $To
            From       = 'DelegationModel@EguibarIT.com'
            Subject    = $Subject
            BodyAsHtml = $true
            SmtpServer = $SmtpServer
            Port       = $SmtpPort
            UseSsl     = $true
            Username   = 'user@example.com'
            Password   = 'password'
        }

        if ($AttachmentPath -and (Test-Path $AttachmentPath)) {
            $emailParams['Attachments'] = $AttachmentPath
        }

        if (-not $PSBoundParameters.ContainsKey('Body')) {

            # No body parsed. Using following body:
            $Body = @"
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
            $emailParams.Add('Body', $Body)
        } else {
            $emailParams.Add('Body', $PSBoundParameters['Body'])
        }
    } #end Begin

    Process {
        try {

            Send-Email @emailParams

            Write-Verbose -Message ('Sent email to {0}' -f $To)
        } catch {
            Write-Error -Message ('Error sending email to {0}: {1}' -f $To, $_)
            throw
        }
    } #end Process

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'sending notification email on Semi-Privileged user creation.'
        )
        Write-Verbose -Message $txt
    } #end End
}
