#Requires -Version 7.0
#Requires -Modules Microsoft.Graph.Authentication, Microsoft.Graph.Applications

<#
.SYNOPSIS
    Creates and configures the Intune-Hydration-Kit application registration with certificate authentication.

.DESCRIPTION
    This script provisions an Azure AD application registration for the Intune Hydration Kit
    with certificate-based authentication. It performs the following:

    1. Connects to Microsoft Graph with admin scopes (interactive)
    2. Creates the application registration if it doesn't exist
    3. Creates the service principal for the application
    4. Generates a self-signed certificate (or uses an existing one)
    5. Attaches the certificate to the application
    6. Configures required Microsoft Graph API permissions
    7. Grants admin consent for all permissions
    8. Verifies the connection using certificate authentication
    9. Confirms the tenant ID matches the expected tenant

.PARAMETER TenantId
    The Azure AD tenant ID (GUID) where the application will be created.

.PARAMETER ApplicationName
    The display name for the application registration. Default: 'Intune-Hydration-Kit'

.PARAMETER CertificateSubject
    The subject name for the certificate. Default: 'CN=Intune-Hydration-Kit'

.PARAMETER CertificateValidityMonths
    Validity period for the certificate in months (1-60). Default: 24

.PARAMETER ExistingCertificateThumbprint
    Thumbprint of an existing certificate to use instead of generating a new one.

.PARAMETER NonExportable
    Create the certificate with KeyExportPolicy NonExportable. The private key cannot be
    exported or backed up, but provides stronger security against credential theft.

.PARAMETER Force
    Skip confirmation prompts and proceed automatically.

.PARAMETER ExportCertificate
    Export the certificate to .cer and .pfx files in the current directory.

.EXAMPLE
    ./Setup-IntuneHydrationApp.ps1 -TenantId "00000000-0000-0000-0000-000000000000"
    Creates the app registration with a new self-signed certificate.

.EXAMPLE
    ./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId -NonExportable -Force
    Creates the app with a non-exportable certificate, skipping prompts.

.EXAMPLE
    ./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId -ExistingCertificateThumbprint "ABC123..."
    Uses an existing certificate from Cert:\CurrentUser\My.

.NOTES
    Requires Global Administrator or Application Administrator role for initial setup.
    Certificate is stored in Cert:\CurrentUser\My by default.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$TenantId,

    [Parameter()]
    [string]$ApplicationName = 'Intune-Hydration-Kit',

    [Parameter()]
    [string]$CertificateSubject = 'CN=Intune-Hydration-Kit',

    [Parameter()]
    [ValidateRange(1, 60)]
    [int]$CertificateValidityMonths = 24,

    [Parameter()]
    [string]$ExistingCertificateThumbprint,

    [Parameter()]
    [switch]$NonExportable,

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$ExportCertificate
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

#region Helper Functions

function Write-SetupLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $colors = @{
        'Info'    = 'Cyan'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Success' = 'Green'
    }

    $icons = @{
        'Info'    = '[i]'
        'Warning' = '[!]'
        'Error'   = '[x]'
        'Success' = '[+]'
    }

    Write-Host "$($icons[$Level]) $Message" -ForegroundColor $colors[$Level]
}

function Confirm-SetupAction {
    param(
        [string]$Message,
        [switch]$Force
    )

    if ($Force) { return $true }

    $response = Read-Host -Prompt "$Message (Y/n)"
    return ($response -eq '' -or $response -eq 'Y' -or $response -eq 'y')
}

function Get-IntuneHydrationApplication {
    param([string]$DisplayName)

    return Get-MgApplication -Filter "displayName eq '$DisplayName'" -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Get-IntuneHydrationServicePrincipal {
    param([string]$AppId)

    return Get-MgServicePrincipal -Filter "appId eq '$AppId'" -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

function Get-RequiredGraphPermissions {
    <#
    .SYNOPSIS
        Returns the required Microsoft Graph permissions for Intune Hydration Kit.
    #>
    return @(
        'DeviceManagementConfiguration.ReadWrite.All',
        'DeviceManagementServiceConfig.ReadWrite.All',
        'DeviceManagementManagedDevices.ReadWrite.All',
        'DeviceManagementScripts.ReadWrite.All',
        'DeviceManagementApps.ReadWrite.All',
        'Group.ReadWrite.All',
        'Policy.Read.All',
        'Policy.ReadWrite.ConditionalAccess',
        'Application.Read.All',
        'Directory.ReadWrite.All'
    )
}

#endregion

#region Main Script

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "  Intune Hydration Kit - App Registration    " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-SetupLog "Target Tenant: $TenantId"
Write-SetupLog "Application Name: $ApplicationName"
Write-SetupLog "Certificate Subject: $CertificateSubject"

if (-not $Force) {
    if (-not (Confirm-SetupAction -Message "Proceed with app registration setup?")) {
        Write-SetupLog "Operation cancelled by user." -Level Warning
        exit 0
    }
}

#region Step 1: Connect with Admin Scopes

Write-Host ""
Write-SetupLog "Step 1: Connecting to Microsoft Graph with admin scopes..."

$adminScopes = @(
    'Application.ReadWrite.All',
    'AppRoleAssignment.ReadWrite.All',
    'Directory.Read.All'
)

# Check existing context
$existingContext = Get-MgContext
if ($existingContext -and $existingContext.TenantId -eq $TenantId) {
    $hasScopes = $true
    foreach ($scope in $adminScopes) {
        if ($existingContext.Scopes -notcontains $scope) {
            $hasScopes = $false
            break
        }
    }

    if ($hasScopes) {
        Write-SetupLog "Using existing Graph session" -Level Success
    }
    else {
        Write-SetupLog "Existing session lacks required scopes, re-authenticating..." -Level Warning
        Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
        $existingContext = $null
    }
}

if (-not $existingContext -or $existingContext.TenantId -ne $TenantId) {
    Write-SetupLog "Opening browser for interactive authentication..."
    Write-SetupLog "Sign in with Global Administrator or Application Administrator credentials" -Level Warning

    try {
        Connect-MgGraph -TenantId $TenantId -Scopes $adminScopes -NoWelcome -ErrorAction Stop | Out-Null
    }
    catch {
        Write-SetupLog "Authentication failed: $($_.Exception.Message)" -Level Error
        throw
    }
}

$context = Get-MgContext
if (-not $context -or -not $context.Account) {
    throw "Microsoft Graph authentication failed: no authenticated account found."
}

# Confirm tenant ID matches
if ($context.TenantId -ne $TenantId) {
    Write-SetupLog "Connected tenant ($($context.TenantId)) does not match expected tenant ($TenantId)" -Level Error
    throw "Tenant ID mismatch. Please ensure you authenticate to the correct tenant."
}

Write-SetupLog "Authenticated as: $($context.Account)" -Level Success
Write-SetupLog "Confirmed Tenant ID: $($context.TenantId)" -Level Success

# Get organization details for confirmation
$org = Invoke-MgGraphRequest -Method GET -Uri "v1.0/organization" -ErrorAction SilentlyContinue
if ($org -and $org.value) {
    Write-SetupLog "Organization: $($org.value[0].displayName)" -Level Success
}

#endregion

#region Step 2: Create or Get Application

Write-Host ""
Write-SetupLog "Step 2: Creating application registration..."

$app = Get-IntuneHydrationApplication -DisplayName $ApplicationName

if (-not $app) {
    Write-SetupLog "Creating new application '$ApplicationName'..."

    if ($PSCmdlet.ShouldProcess($ApplicationName, "Create application registration")) {
        $appParams = @{
            DisplayName    = $ApplicationName
            SignInAudience = 'AzureADMyOrg'
            Description    = 'Application for Intune Hydration Kit - automated tenant configuration'
            Notes          = 'Created by Setup-IntuneHydrationApp.ps1. Uses certificate authentication.'
        }

        $app = New-MgApplication @appParams -ErrorAction Stop
        Write-SetupLog "Application created: AppId = $($app.AppId)" -Level Success
    }
}
else {
    Write-SetupLog "Found existing application: AppId = $($app.AppId)" -Level Success
}

#endregion

#region Step 3: Create or Get Service Principal

Write-Host ""
Write-SetupLog "Step 3: Creating service principal..."

$sp = Get-IntuneHydrationServicePrincipal -AppId $app.AppId

if (-not $sp) {
    Write-SetupLog "Creating service principal for application..."

    if ($PSCmdlet.ShouldProcess($app.AppId, "Create service principal")) {
        $sp = New-MgServicePrincipal -AppId $app.AppId -ErrorAction Stop
        Write-SetupLog "Service principal created: Id = $($sp.Id)" -Level Success
    }
}
else {
    Write-SetupLog "Found existing service principal: Id = $($sp.Id)" -Level Success
}

#endregion

#region Step 4: Generate or Use Certificate

Write-Host ""
Write-SetupLog "Step 4: Configuring certificate authentication..."

$certificate = $null

if ($ExistingCertificateThumbprint) {
    # Use existing certificate
    $normalizedThumbprint = $ExistingCertificateThumbprint -replace '[^a-fA-F0-9]', ''
    $certificate = Get-ChildItem -Path 'Cert:\CurrentUser\My' |
        Where-Object { $_.Thumbprint -eq $normalizedThumbprint } |
        Select-Object -First 1

    if (-not $certificate) {
        throw "Certificate with thumbprint '$ExistingCertificateThumbprint' not found in Cert:\CurrentUser\My"
    }

    Write-SetupLog "Using existing certificate: $($certificate.Subject)" -Level Success
    Write-SetupLog "Thumbprint: $($certificate.Thumbprint)"
}
else {
    # Check for existing certificate with matching subject
    $certificate = Get-ChildItem -Path 'Cert:\CurrentUser\My' |
        Where-Object { $_.Subject -eq $CertificateSubject } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1

    if ($certificate) {
        Write-SetupLog "Found existing certificate with subject '$CertificateSubject'"
        Write-SetupLog "Thumbprint: $($certificate.Thumbprint), Expires: $($certificate.NotAfter)"

        if (-not $Force) {
            $useExisting = Confirm-SetupAction -Message "Use existing certificate?"
            if (-not $useExisting) {
                $certificate = $null
            }
        }
    }

    if (-not $certificate) {
        # Generate new self-signed certificate
        $exportPolicy = if ($NonExportable) { 'NonExportable' } else { 'Exportable' }
        $notAfter = (Get-Date).AddMonths($CertificateValidityMonths)

        Write-SetupLog "Generating new self-signed certificate..."
        Write-SetupLog "Subject: $CertificateSubject"
        Write-SetupLog "Expires: $notAfter"
        Write-SetupLog "Key Export Policy: $exportPolicy"

        if ($PSCmdlet.ShouldProcess($CertificateSubject, "Create self-signed certificate")) {
            $certParams = @{
                Subject           = $CertificateSubject
                CertStoreLocation = 'Cert:\CurrentUser\My'
                KeyExportPolicy   = $exportPolicy
                KeySpec           = 'Signature'
                KeyLength         = 2048
                KeyAlgorithm      = 'RSA'
                HashAlgorithm     = 'SHA256'
                NotAfter          = $notAfter
            }

            $certificate = New-SelfSignedCertificate @certParams -ErrorAction Stop
            Write-SetupLog "Certificate created: Thumbprint = $($certificate.Thumbprint)" -Level Success

            if ($NonExportable) {
                Write-SetupLog "Certificate has non-exportable private key (cannot be backed up)" -Level Warning
            }
        }
    }
}

# Export certificate files if requested
if ($ExportCertificate -and $certificate -and -not $NonExportable) {
    $baseName = $ApplicationName -replace '[^a-zA-Z0-9-]', ''
    $cerPath = Join-Path -Path $PWD -ChildPath "$baseName.cer"
    $pfxPath = Join-Path -Path $PWD -ChildPath "$baseName.pfx"

    # Export public key (.cer)
    Export-Certificate -Cert $certificate -FilePath $cerPath -Type CERT | Out-Null
    Write-SetupLog "Public certificate exported: $cerPath" -Level Success

    # Export with private key (.pfx)
    $pfxPassword = Read-Host -Prompt "Enter password for PFX export" -AsSecureString
    Export-PfxCertificate -Cert $certificate -FilePath $pfxPath -Password $pfxPassword | Out-Null
    Write-SetupLog "Private certificate exported: $pfxPath" -Level Success
    Write-SetupLog "Store the PFX file securely - it contains the private key" -Level Warning
}

#endregion

#region Step 5: Attach Certificate to Application

Write-Host ""
Write-SetupLog "Step 5: Attaching certificate to application..."

# Refresh application to get current keyCredentials
$app = Get-MgApplication -ApplicationId $app.Id -ErrorAction Stop

# Check if certificate is already attached
$thumbBytes = $certificate.GetCertHash()
$thumbB64 = [System.Convert]::ToBase64String($thumbBytes)
$hasKey = $false

foreach ($key in $app.KeyCredentials) {
    if ($key.CustomKeyIdentifier) {
        $existingB64 = [System.Convert]::ToBase64String($key.CustomKeyIdentifier)
        if ($existingB64 -eq $thumbB64) {
            $hasKey = $true
            break
        }
    }
}

if ($hasKey) {
    Write-SetupLog "Certificate is already attached to the application" -Level Success
}
else {
    Write-SetupLog "Adding certificate to application keyCredentials..."

    if ($PSCmdlet.ShouldProcess($app.AppId, "Attach certificate")) {
        $keyCredential = @{
            Type              = 'AsymmetricX509Cert'
            Usage             = 'Verify'
            Key               = $certificate.RawData
            DisplayName       = "IntuneHydrationKit-$($certificate.Thumbprint.Substring(0, 8))"
            StartDateTime     = $certificate.NotBefore
            EndDateTime       = $certificate.NotAfter
            CustomKeyIdentifier = $thumbBytes
        }

        # Combine with existing credentials if any
        $existingKeys = @()
        if ($app.KeyCredentials) {
            foreach ($key in $app.KeyCredentials) {
                # Cannot preserve existing keys without the Key property (Graph security)
                # Only add new certificate
            }
        }

        Update-MgApplication -ApplicationId $app.Id -KeyCredentials @($keyCredential) -ErrorAction Stop | Out-Null
        Write-SetupLog "Certificate attached successfully" -Level Success
    }
}

#endregion

#region Step 6: Configure API Permissions

Write-Host ""
Write-SetupLog "Step 6: Configuring Microsoft Graph API permissions..."

$requiredPermissions = Get-RequiredGraphPermissions
Write-SetupLog "Required permissions:"
foreach ($perm in $requiredPermissions) {
    Write-Host "   - $perm" -ForegroundColor Gray
}

# Get Microsoft Graph service principal
$graphSp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'" -ErrorAction Stop

# Build RequiredResourceAccess for the application
$resourceAccess = @()
foreach ($permName in $requiredPermissions) {
    $appRole = $graphSp.AppRoles | Where-Object { $_.Value -eq $permName -and $_.AllowedMemberTypes -contains 'Application' } | Select-Object -First 1

    if ($appRole) {
        $resourceAccess += @{
            Id   = $appRole.Id
            Type = 'Role'  # Application permission
        }
    }
    else {
        Write-SetupLog "App role not found for: $permName" -Level Warning
    }
}

if ($resourceAccess.Count -eq 0) {
    throw "No valid application permissions found. Check Microsoft Graph service principal."
}

$requiredResourceAccess = @(
    @{
        ResourceAppId  = '00000003-0000-0000-c000-000000000000'  # Microsoft Graph
        ResourceAccess = $resourceAccess
    }
)

if ($PSCmdlet.ShouldProcess($app.AppId, "Configure API permissions")) {
    Update-MgApplication -ApplicationId $app.Id -RequiredResourceAccess $requiredResourceAccess -ErrorAction Stop | Out-Null
    Write-SetupLog "API permissions configured on application" -Level Success
}

#endregion

#region Step 7: Grant Admin Consent

Write-Host ""
Write-SetupLog "Step 7: Granting admin consent for API permissions..."

# Get existing app role assignments
$existingAssignments = Get-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $sp.Id -All -ErrorAction SilentlyContinue

$grantedCount = 0
$skippedCount = 0

foreach ($access in $resourceAccess) {
    $alreadyAssigned = $existingAssignments | Where-Object {
        $_.AppRoleId -eq $access.Id -and $_.ResourceId -eq $graphSp.Id
    }

    if ($alreadyAssigned) {
        $skippedCount++
        continue
    }

    $roleName = ($graphSp.AppRoles | Where-Object { $_.Id -eq $access.Id }).Value

    if ($PSCmdlet.ShouldProcess($roleName, "Grant admin consent")) {
        try {
            $assignmentParams = @{
                ServicePrincipalId = $sp.Id
                PrincipalId        = $sp.Id
                ResourceId         = $graphSp.Id
                AppRoleId          = $access.Id
            }

            New-MgServicePrincipalAppRoleAssignment @assignmentParams -ErrorAction Stop | Out-Null
            $grantedCount++
            Write-Host "   Granted: $roleName" -ForegroundColor Green
        }
        catch {
            Write-SetupLog "Failed to grant consent for $roleName : $($_.Exception.Message)" -Level Warning
        }
    }
}

if ($grantedCount -gt 0) {
    Write-SetupLog "Admin consent granted for $grantedCount permissions" -Level Success
}
if ($skippedCount -gt 0) {
    Write-SetupLog "$skippedCount permissions already consented" -Level Info
}

#endregion

#region Step 8: Disconnect Admin Session

Write-Host ""
Write-SetupLog "Step 8: Disconnecting admin session..."
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null

#endregion

#region Step 9: Verify Certificate Authentication

Write-Host ""
Write-SetupLog "Step 9: Verifying certificate-based authentication..."

Write-SetupLog "Connecting to Graph using certificate..."

try {
    Connect-MgGraph -TenantId $TenantId -ClientId $app.AppId -CertificateThumbprint $certificate.Thumbprint -NoWelcome -ErrorAction Stop | Out-Null
}
catch {
    Write-SetupLog "Certificate authentication failed: $($_.Exception.Message)" -Level Error
    Write-SetupLog "The app registration was created, but certificate auth could not be verified." -Level Warning
    Write-SetupLog "This may be due to replication delays. Wait a few minutes and try connecting manually." -Level Warning
    throw
}

$verifyContext = Get-MgContext

if (-not $verifyContext) {
    throw "Certificate authentication verification failed: no context returned."
}

# Final tenant ID confirmation
if ($verifyContext.TenantId -ne $TenantId) {
    Write-SetupLog "CRITICAL: Connected tenant ($($verifyContext.TenantId)) does not match expected tenant ($TenantId)" -Level Error
    Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null
    throw "Tenant ID mismatch during certificate authentication verification."
}

Write-SetupLog "Certificate authentication verified successfully" -Level Success
Write-SetupLog "Connected Tenant ID: $($verifyContext.TenantId)" -Level Success
Write-SetupLog "Client ID: $($verifyContext.ClientId)" -Level Success
Write-SetupLog "Auth Type: $($verifyContext.AuthType)" -Level Success

# Disconnect after verification
Disconnect-MgGraph -ErrorAction SilentlyContinue | Out-Null

#endregion

#region Summary

Write-Host ""
Write-Host "=============================================" -ForegroundColor Green
Write-Host "  Setup Complete                             " -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""
Write-SetupLog "Application Name: $ApplicationName" -Level Success
Write-SetupLog "Application ID (ClientId): $($app.AppId)" -Level Success
Write-SetupLog "Tenant ID: $TenantId" -Level Success
Write-SetupLog "Certificate Subject: $CertificateSubject" -Level Success
Write-SetupLog "Certificate Thumbprint: $($certificate.Thumbprint)" -Level Success
Write-SetupLog "Certificate Expires: $($certificate.NotAfter)" -Level Success
Write-Host ""
Write-Host "Update your settings.json with the following:" -ForegroundColor Yellow
Write-Host ""
Write-Host @"
{
    "tenant": {
        "tenantId": "$TenantId"
    },
    "authentication": {
        "mode": "certificate",
        "clientId": "$($app.AppId)",
        "certificateThumbprint": "$($certificate.Thumbprint)",
        "environment": "Global"
    }
}
"@ -ForegroundColor Cyan
Write-Host ""
Write-SetupLog "Certificate is stored in: Cert:\CurrentUser\My\$($certificate.Thumbprint)"
Write-Host ""

#endregion
