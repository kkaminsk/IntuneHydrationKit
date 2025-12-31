function Connect-IntuneHydration {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph with required scopes for Intune hydration
    .DESCRIPTION
        Establishes authentication to Microsoft Graph using interactive, client secret,
        or certificate-based authentication.
        Supports multiple cloud environments: Global (Commercial), USGov, USGovDoD, Germany, China.

        Certificate authentication is the recommended method for automation scenarios
        as it provides stronger security than client secrets.
    .PARAMETER TenantId
        The Azure AD tenant ID (GUID or domain name)
    .PARAMETER ClientId
        Application (client) ID for app registration auth
    .PARAMETER ClientSecret
        Client secret for authentication (use SecureString for production)
    .PARAMETER CertificateThumbprint
        Thumbprint of the certificate to use for authentication.
        Certificate must be in Cert:\CurrentUser\My or Cert:\LocalMachine\My
    .PARAMETER CertificateSubject
        Subject name of the certificate to use for authentication (e.g., 'CN=Intune-Hydration-Kit').
        Uses the most recent valid certificate with matching subject.
    .PARAMETER Interactive
        Use interactive authentication
    .PARAMETER Environment
        Graph environment: Global, USGov, USGovDoD, Germany, China
    .EXAMPLE
        Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" -Interactive
        Connects using browser-based interactive authentication.
    .EXAMPLE
        Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" -ClientId "app-id" -ClientSecret $secret
        Connects using client secret authentication (not recommended for production).
    .EXAMPLE
        Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" -ClientId "app-id" -CertificateThumbprint "ABC123..."
        Connects using certificate authentication with thumbprint lookup.
    .EXAMPLE
        Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" -ClientId "app-id" -CertificateSubject "CN=Intune-Hydration-Kit"
        Connects using certificate authentication with subject lookup.
    .EXAMPLE
        Connect-IntuneHydration -TenantId "contoso.onmicrosoft.us" -Interactive -Environment USGov
        Connects to US Government cloud using interactive authentication.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$TenantId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateThumbprint')]
        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateSubject')]
        [ValidateNotNullOrEmpty()]
        [string]$ClientId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ClientSecret')]
        [ValidateNotNullOrEmpty()]
        [SecureString]$ClientSecret,

        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateThumbprint')]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory = $true, ParameterSetName = 'CertificateSubject')]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateSubject,

        [Parameter(ParameterSetName = 'Interactive')]
        [switch]$Interactive,

        [Parameter()]
        [ValidateSet('Global', 'USGov', 'USGovDoD', 'Germany', 'China')]
        [string]$Environment = 'Global'
    )

    $scopes = @(
        "DeviceManagementConfiguration.ReadWrite.All",
        "DeviceManagementServiceConfig.ReadWrite.All",
        "DeviceManagementManagedDevices.ReadWrite.All",
        "DeviceManagementScripts.ReadWrite.All",
        "DeviceManagementApps.ReadWrite.All",
        "Group.ReadWrite.All",
        "Policy.Read.All",
        "Policy.ReadWrite.ConditionalAccess",
        "Application.Read.All",
        "Directory.ReadWrite.All"
    )

    # Store environment for use by other functions
    $script:GraphEnvironment = $Environment
    $script:GraphEndpoint = switch ($Environment) {
        'Global' { 'https://graph.microsoft.com' }
        'USGov' { 'https://graph.microsoft.us' }
        'USGovDoD' { 'https://dod-graph.microsoft.us' }
        'Germany' { 'https://graph.microsoft.de' }
        'China' { 'https://microsoftgraph.chinacloudapi.cn' }
    }

    Write-Host "Connecting to $Environment environment ($script:GraphEndpoint)"

    # Resolve certificate if using certificate authentication
    $certificate = $null
    if ($CertificateThumbprint) {
        # Normalize thumbprint (remove spaces/colons if copy-pasted from cert manager)
        $normalizedThumbprint = $CertificateThumbprint -replace '[^a-fA-F0-9]', ''

        # Search CurrentUser first, then LocalMachine
        $certificate = Get-ChildItem -Path 'Cert:\CurrentUser\My' -ErrorAction SilentlyContinue |
            Where-Object { $_.Thumbprint -eq $normalizedThumbprint } |
            Select-Object -First 1

        if (-not $certificate) {
            $certificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
                Where-Object { $_.Thumbprint -eq $normalizedThumbprint } |
                Select-Object -First 1
        }

        if (-not $certificate) {
            throw "Certificate with thumbprint '$CertificateThumbprint' not found in Cert:\CurrentUser\My or Cert:\LocalMachine\My"
        }

        Write-Host "Using certificate: $($certificate.Subject) (Thumbprint: $($certificate.Thumbprint))"
    }
    elseif ($CertificateSubject) {
        # Find certificate by subject - prefer most recent valid certificate
        $certificate = Get-ChildItem -Path 'Cert:\CurrentUser\My' -ErrorAction SilentlyContinue |
            Where-Object { $_.Subject -eq $CertificateSubject -and $_.NotAfter -gt (Get-Date) } |
            Sort-Object NotAfter -Descending |
            Select-Object -First 1

        if (-not $certificate) {
            $certificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue |
                Where-Object { $_.Subject -eq $CertificateSubject -and $_.NotAfter -gt (Get-Date) } |
                Sort-Object NotAfter -Descending |
                Select-Object -First 1
        }

        if (-not $certificate) {
            throw "Valid certificate with subject '$CertificateSubject' not found in Cert:\CurrentUser\My or Cert:\LocalMachine\My"
        }

        Write-Host "Using certificate: $($certificate.Subject) (Thumbprint: $($certificate.Thumbprint), Expires: $($certificate.NotAfter))"
    }

    try {
        $connectParams = @{
            TenantId    = $TenantId
            Environment = $Environment
            NoWelcome   = $true
            ErrorAction = 'Stop'
        }

        if ($Interactive) {
            # Interactive authentication with delegated scopes
            $connectParams['Scopes'] = $scopes
            Write-Host "Initiating interactive authentication..."
        }
        elseif ($certificate) {
            # Certificate-based authentication (app-only)
            $connectParams['ClientId'] = $ClientId
            $connectParams['CertificateThumbprint'] = $certificate.Thumbprint
            Write-Host "Connecting with certificate authentication..."
        }
        else {
            # Client secret authentication (app-only)
            $credential = New-Object System.Management.Automation.PSCredential($ClientId, $ClientSecret)
            $connectParams['ClientSecretCredential'] = $credential
            Write-Host "Connecting with client secret authentication..."
        }

        Connect-MgGraph @connectParams

        # Verify connection and confirm tenant ID
        $context = Get-MgContext
        if (-not $context) {
            throw "Connection established but no context returned."
        }

        # Confirm tenant ID matches expected tenant
        # Note: TenantId parameter might be a domain name, context.TenantId is always GUID
        $connectedTenantId = $context.TenantId

        # If user provided GUID, verify it matches
        $providedIsGuid = $TenantId -match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        if ($providedIsGuid -and $connectedTenantId -ne $TenantId) {
            Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
            throw "Tenant ID mismatch! Expected: $TenantId, Connected: $connectedTenantId"
        }

        $script:HydrationState.Connected = $true
        $script:HydrationState.TenantId = $connectedTenantId
        $script:HydrationState.Environment = $Environment
        $script:HydrationState.AuthMode = if ($Interactive) { 'Interactive' } elseif ($certificate) { 'Certificate' } else { 'ClientSecret' }

        # Display connection confirmation
        Write-Host "Successfully connected to tenant: $(Get-ObfuscatedTenantId -TenantId $connectedTenantId) ($Environment)"
        Write-Host "Authentication mode: $($script:HydrationState.AuthMode)"

        # For app-only auth, show the client ID
        if ($context.ClientId -and -not $Interactive) {
            Write-Host "Client ID: $($context.ClientId)"
        }

        # Confirm tenant by fetching organization info
        try {
            $org = Invoke-MgGraphRequest -Method GET -Uri "v1.0/organization" -ErrorAction SilentlyContinue
            if ($org -and $org.value -and $org.value[0].displayName) {
                Write-Host "Organization: $($org.value[0].displayName)"
            }
        }
        catch {
            # Organization lookup may fail with limited permissions, not critical
            Write-Verbose "Could not retrieve organization details: $_"
        }

    } catch {
        Write-Error "Failed to connect to Microsoft Graph: $_"
        throw
    }
}
