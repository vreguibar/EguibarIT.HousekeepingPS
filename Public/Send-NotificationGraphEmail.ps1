Function Send-NotificationGraphEmail {

    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([void])]

    Param (

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

    Begin {

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

    Process {

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

    End {
        $txt = ($Variables.FooterHousekeeping -f $MyInvocation.InvocationName,
            'sending notification email on Semi-Privileged user creation.'
        )
        Write-Verbose -Message $txt
    } #end End
} #end Function
