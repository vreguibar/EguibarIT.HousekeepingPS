$Constants = [ordered] @{

    # Null GUID which is considered as "All"
    #$guidNull  = New-Object -TypeName Guid -ArgumentList 00000000-0000-0000-0000-000000000000
    guidNull   = [System.guid]::New('00000000-0000-0000-0000-000000000000')

    # Horizontal Tab
    HTab       = "`t"

    # New Line
    NL         = [System.Environment]::NewLine

    # Regular Expression (RegEx) for Email
    EmailRegEx = "^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$"

}

$Splat = @{
    Name        = 'Constants'
    Value       = $Constants
    Description = 'Contains the Constant values used on this module, like GUIDnull, Horizontal Tab or NewLine.'
    Scope       = 'Global'
    Option      = 'Constant'
    Force       = $true
}

New-Variable @Splat
