$Variables = [ordered] @{

    # Active Directory DistinguishedName
    AdDN                       = $null

    # Configuration Naming Context
    configurationNamingContext = $null

    # Active Directory DistinguishedName
    defaultNamingContext       = $null

    # Get current DNS domain name
    DnsFqdn                    = $null

    # Hashtable containing the mappings between SchemaExtendedRights and GUID's
    ExtendedRightsMap          = $null

    # Hashtable containing the mappings between ClassSchema/AttributeSchema and GUID's
    GuidMap                    = $null

    # Naming Contexts
    namingContexts             = $null

    # Partitions Container
    PartitionsContainer        = $null

    # Root Domain Naming Context
    rootDomainNamingContext    = $null

    # Schema Naming Context
    SchemaNamingContext        = $null

    # Well-Known SIDs
    WellKnownSIDs              = $null

    # Standard header used on each function on the Begin section
    HeaderHousekeeping         = @'

         ═══════════════════════════════════════════════════════════════════════════
                              EguibarIT.HousekeepingPS module
         ═══════════════════════════════════════════════════════════════════════════
            Date:     {0}
            Starting: {1}

          Parameters used by the function... {2}

'@

    # Standard footer used on each function on the Begin section
    FooterHousekeeping         = @'

          Function {0} finished {1}"

         ───────────────────────────────────────────────────────────────────────────

'@

}

$Splat = @{
    Name        = 'Variables'
    Value       = $Variables
    Description = 'Define a Module variable, containing Schema GUIDs, Naming Contexts or Well Known SIDs'
    Scope       = 'Global'
    Force       = $true
}
New-Variable @Splat

# Create variable with $Nulls, then call Initialize-ModuleVariable to fill it up.
