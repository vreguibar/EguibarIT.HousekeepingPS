function Send-NotificationGraphEmail {

    <#
        .SYNOPSIS
            Sends notification emails using Microsoft Graph API.

        .DESCRIPTION
            The Send-NotificationGraphEmail function sends notification emails using Microsoft Graph API with certificate-based authentication.
            It's designed to send automated notifications from registered applications using OAuth 2.0 authentication flow.
            The function connects to Microsoft Graph using a registered application's client ID, tenant ID, and certificate thumbprint.

        .PARAMETER Recipient
            Email address of the recipient (to whom) of the email.
            Accepts System.Net.Mail.MailAddress objects for validation.

        .PARAMETER Subject
            Subject line of the email message.

        .PARAMETER Body
            HTML content of the email message body.

        .PARAMETER From
            Valid email address of the sending user. This address will be used to send the notification.
            Must be a valid mailbox in the tenant and the registered application must have permission to send as this user.

        .PARAMETER ClientId
            Application registered ID (Client ID). This registered application is allowed to send email.
            Default value is from EguibarIT registered App.

        .PARAMETER TenantId
            Configured Tenant ID to be used for authentication.
            Default value is from EguibarIT Tenant.

        .PARAMETER CertThumbprint
            Certificate thumbprint used to authenticate to tenant and use registered app.
            The certificate must be installed in the local certificate store and configured in the Azure AD application.
            Default value is from EguibarIT server.

        .EXAMPLE
            Send-NotificationGraphEmail -Recipient "user@contoso.com" -Subject "Test Email" -Body "<h1>Test Message</h1>" -From "sender@contoso.com"

            Sends a test email using the default application registration settings.

        .EXAMPLE
            Send-NotificationGraphEmail -Recipient "admin@contoso.com" -Subject "Account Created" -Body $HtmlBody -From "noreply@contoso.com" -ClientId "12345-67890" -TenantId "abcdef-12345" -CertThumbprint "ABC123DEF456"

            Sends a notification email using custom application registration and certificate settings.

        .EXAMPLE
            $EmailParams = @{
                Recipient = "user@contoso.com"
                Subject = "Welcome to the system"
                Body = Get-Content -Path ".\WelcomeTemplate.html" -Raw
                From = "welcome@contoso.com"
            }
            Send-NotificationGraphEmail @EmailParams

            Sends a welcome email using splatting with an HTML template file.

        .INPUTS
            [System.Net.Mail.MailAddress]
            You can pipe email addresses to the Recipient parameter.

            [System.String]
            You can pipe strings to the Subject and Body parameters.

        .OUTPUTS
            [System.Void]
            This function does not return any objects.

        .NOTES
            Used Functions:
                Name                             ║ Module/Namespace
                ═════════════════════════════════╬══════════════════════════════
                Connect-MgGraph                  ║ Microsoft.Graph.Authentication
                Send-MgUserMail                  ║ Microsoft.Graph.Users.Actions
                Write-Verbose                    ║ Microsoft.PowerShell.Utility
                Write-Error                      ║ Microsoft.PowerShell.Utility
                Get-Date                         ║ Microsoft.PowerShell.Utility
                Get-FunctionDisplay              ║ EguibarIT.HousekeepingPS

        .NOTES
            Version:         1.0
            DateModified:    10/Jul/2025
            LastModifiedBy:  Vicente Rodriguez Eguibar
                        vicente@eguibarit.com
                        Eguibar IT
                        http://www.eguibarit.com

        .LINK
            https://github.com/vreguibar/EguibarIT.HousekeepingPS/blob/main/Public/Send-NotificationGraphEmail.ps1

        .LINK
            https://docs.microsoft.com/en-us/powershell/module/microsoft.graph.users.actions/send-mgusermail

        .LINK
            https://docs.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph

        .COMPONENT
            Email Notification

        .ROLE
            Service Account

        .FUNCTIONALITY
            Sends automated notification emails using Microsoft Graph API with certificate-based authentication.
    #>

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([void])]

    param (

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Email address of the recipient (to whom) of the email.',
            Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('To', 'EmailTo', 'EmailAddress')]
        [System.Net.Mail.MailAddress]
        $Recipient,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Subject of the email.',
            Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Subject,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Body (content) of the email.',
            Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Body,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Valid Email of the sending user. This address will be used to send the notification.',
            Position = 3)]
        [ValidateNotNullOrEmpty()]
        [System.Net.Mail.MailAddress]
        $From,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Application registered ID (Client ID). This App registered is allowed to send email.',
            Position = 4)]
        [PSDefaultValue(Help = 'Default Value is from EguibarIT registerd App')]
        [string]
        $ClientId = '67b0de82-6ee8-4720-b54e-c3932b7e1ff5',

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Configured Tenant to be used..',
            Position = 5)]
        [PSDefaultValue(Help = 'Default Value is from EguibarIT Tenant')]
        [string]
        $TenantId = '80be540f-1de9-43fe-aab7-da6232ba820f',

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true,
            ValueFromRemainingArguments = $true,
            HelpMessage = 'Certificate thumbprint used to authenticate to tenant and use registered app.',
            Position = 6)]
        [PSDefaultValue(Help = 'Default Value is from EguibarIT server.')]
        [string]
        $CertThumbprint = 'C5EF34A09BEAE5C75D904DA8DD54825D0787B60C'
    )

    begin {

        $txt = ($Variables.HeaderHousekeeping -f
            (Get-Date).ToShortDateString(),
            $MyInvocation.Mycommand,
            (Get-FunctionDisplay -Hashtable $PsBoundParameters -Verbose:$False)
        )
        Write-Verbose -Message $txt

        ##############################
        # Variables Definition

        [Hashtable]$Splat = [hashtable]::New([StringComparer]::OrdinalIgnoreCase)


        $Message = @{
            subject                    = $PSBoundParameters['Subject'];
            importance                 = 'High'
            isDeliveryReceiptRequested = 'True'
            isReadReceiptRequested     = 'True'
            toRecipients               = @(
                @{
                    emailAddress = @{
                        address = $PSBoundParameters['Recipient'];
                    }
                }
            );
            body                       = @{
                contentType = 'HTML'
                content     = $PSBoundParameters['Body']
            }
            SaveToSentItems            = 'false'
        }


    } #end Begin

    process {

        # Connect to MS.Graph
        try {

            $Splat = @{
                ClientId              = $PSBoundParameters['ClientId']
                TenantId              = $PSBoundParameters['TenantId']
                CertificateThumbprint = $PSBoundParameters['CertThumbprint']
            }
            Connect-MgGraph @Splat
            #Select-MgProfile -Name v1.0
        } catch {
            Write-Error -Message ('Something went wrong while connecting to Graph. {0}' -f $_)
        } #end Try-Catch

        # Send email using Graph
        try {

            Send-MgUserMail -UserId $PSBoundParameters['From'] -Message $Message

        } catch {
            Write-Error -Message ('Something went wrong while sending email. {0}' -f $_)
        } #end Try-Catch

    } #end Process

    end {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'sending notification email on Semi-Privileged user creation.'
        )
        Write-Verbose -Message $txt
    } #end End
} #end Function
