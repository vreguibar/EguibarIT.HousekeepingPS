$Constants = [ordered] @{

    # Null GUID which is considered as "All"
    #$guidNull  = New-Object -TypeName Guid -ArgumentList 00000000-0000-0000-0000-000000000000
    guidNull = [System.guid]::New('00000000-0000-0000-0000-000000000000')

    # Horizontal Tab
    HTab     = "`t"

    # New Line
    NL       = [System.Environment]::NewLine

    # Standard header used on each function on the Begin section
    Header   = @'

         ═══════════════════════════════════════════════════════════════════════════
                              EguibarIT.HousekeepingPS module
         ═══════════════════════════════════════════════════════════════════════════
            Date:     {0}
            Starting: {1}

          Parameters used by the function... {2}

'@

    # Standard footer used on each function on the Begin section
    Footer   = @'

          Function {0} finished {1}"

         ───────────────────────────────────────────────────────────────────────────

'@

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
