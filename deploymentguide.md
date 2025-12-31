# Intune Hydration Kit - Deployment Guide

A comprehensive technical guide for deploying the Intune Hydration Kit to bootstrap Microsoft Intune tenants with baseline configurations.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [Authentication](#authentication)
5. [Execution](#execution)
6. [Execution Flow](#execution-flow)
7. [Logging](#logging)
8. [Reports](#reports)
9. [Cleanup and Deletion](#cleanup-and-deletion)
10. [Troubleshooting](#troubleshooting)
11. [Advanced Scenarios](#advanced-scenarios)

---

## Prerequisites

### PowerShell Version

PowerShell 7.0 or later is required. The module will not load on Windows PowerShell 5.1.

```powershell
# Check PowerShell version
$PSVersionTable.PSVersion

# Install PowerShell 7 if needed (Windows)
winget install Microsoft.PowerShell

# Or download from GitHub
# https://github.com/PowerShell/PowerShell/releases
```

### Required Modules

Only `Microsoft.Graph.Authentication` is required. All Graph API calls use `Invoke-MgGraphRequest` directly.

```powershell
# Install the required module
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force

# Verify installation
Get-Module Microsoft.Graph.Authentication -ListAvailable
```

### Required Graph API Permissions

The authenticated identity (user or service principal) must have these permissions:

| Permission | Purpose |
|------------|---------|
| `DeviceManagementConfiguration.ReadWrite.All` | Configuration policies, baselines |
| `DeviceManagementServiceConfig.ReadWrite.All` | Enrollment profiles, device filters |
| `DeviceManagementManagedDevices.ReadWrite.All` | Device management operations |
| `DeviceManagementScripts.ReadWrite.All` | Custom compliance scripts |
| `DeviceManagementApps.ReadWrite.All` | App protection policies |
| `Group.ReadWrite.All` | Dynamic group creation |
| `Policy.Read.All` | Query existing CA policies |
| `Policy.ReadWrite.ConditionalAccess` | Conditional Access policies |
| `Application.Read.All` | CA policy app targeting |
| `Directory.ReadWrite.All` | Directory operations |

### Intune Licensing

The tenant must have active Intune licensing. Supported license SKUs:
- `INTUNE_A` (Intune Plan 1)
- `INTUNE_EDU` (Intune for Education)
- `EMSPREMIUM` (Enterprise Mobility + Security E3/E5)

---

## Installation

### Clone the Repository

```powershell
git clone https://github.com/jorgeasaurus/Intune-Hydration-Kit.git
cd Intune-Hydration-Kit
```

### Import the Module

```powershell
# Import from the module manifest
Import-Module ./IntuneHydrationKit.psd1 -Force

# Verify loaded functions
Get-Command -Module IntuneHydrationKit
```

Expected output:
```
CommandType     Name                                    Version    Source
-----------     ----                                    -------    ------
Function        Connect-IntuneHydration                 0.1.4      IntuneHydrationKit
Function        Get-OpenIntuneBaseline                  0.1.4      IntuneHydrationKit
Function        Import-IntuneBaseline                   0.1.4      IntuneHydrationKit
Function        Import-IntuneCompliancePolicy           0.1.4      IntuneHydrationKit
...
```

---

## Configuration

### Create Settings File

```powershell
Copy-Item settings.example.json settings.json
```

### Settings File Structure

```json
{
    "tenant": {
        "tenantId": "00000000-0000-0000-0000-000000000000",
        "tenantName": "contoso.onmicrosoft.com"
    },
    "authentication": {
        "mode": "interactive",
        "clientId": null,
        "clientSecret": null,
        "certificateThumbprint": null,
        "certificateSubject": null,
        "environment": "Global"
    },
    "options": {
        "dryRun": false,
        "create": true,
        "delete": false,
        "verbose": true
    },
    "imports": {
        "openIntuneBaseline": true,
        "complianceTemplates": true,
        "appProtection": true,
        "notificationTemplates": true,
        "enrollmentProfiles": true,
        "dynamicGroups": true,
        "deviceFilters": true,
        "conditionalAccess": true
    },
    "openIntuneBaseline": {
        "repoUrl": "https://github.com/SkipToTheEndpoint/OpenIntuneBaseline",
        "branch": "main",
        "downloadPath": null
    },
    "reporting": {
        "outputPath": "./Reports",
        "formats": ["markdown", "json"]
    }
}
```

### Configuration Options Reference

#### Tenant Configuration

| Field | Type | Description |
|-------|------|-------------|
| `tenantId` | GUID | Azure AD tenant ID (required) |
| `tenantName` | string | Tenant domain name (informational) |

#### Operation Modes

| Option | Type | Description |
|--------|------|-------------|
| `dryRun` | bool | Preview changes without applying (equivalent to `-WhatIf`) |
| `create` | bool | Enable creation of new objects |
| `delete` | bool | Enable deletion of kit-created objects |
| `verbose` | bool | Enable verbose console and log output |

**Important:** `create` and `delete` are mutually exclusive. Only one can be `true`.

#### Import Toggles

Each import type can be individually enabled or disabled:

```json
"imports": {
    "openIntuneBaseline": true,     // 70+ security baseline policies
    "complianceTemplates": true,    // 10 multi-platform compliance policies
    "appProtection": true,          // iOS/Android MAM policies
    "notificationTemplates": true,  // Compliance notification templates
    "enrollmentProfiles": true,     // Autopilot, ESP profiles
    "dynamicGroups": true,          // 12 dynamic device groups
    "deviceFilters": true,          // 12 assignment filters
    "conditionalAccess": true       // 13 CA starter policies (disabled)
}
```

---

## Authentication

The kit supports three authentication methods:

| Method | Use Case | Security Level |
|--------|----------|----------------|
| Interactive | Manual testing, initial setup | User credentials |
| Certificate | Production automation, CI/CD | **Recommended** |
| Client Secret | Legacy automation | Not recommended |

### Interactive Authentication (Recommended for Testing)

```json
"authentication": {
    "mode": "interactive",
    "environment": "Global"
}
```

```powershell
# Execution triggers browser-based authentication
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json
```

The browser will open for Azure AD sign-in. The user must have sufficient permissions to consent to the required scopes.

---

### Certificate Authentication (Recommended for Production)

Certificate-based authentication provides stronger security than client secrets and is the recommended method for automation scenarios. The kit includes a setup script that automates the entire process.

#### Automated Setup with Setup-IntuneHydrationApp.ps1

The `Setup-IntuneHydrationApp.ps1` script handles all app registration tasks:

1. Creates the Azure AD application registration
2. Creates the service principal
3. Generates a self-signed certificate (or uses an existing one)
4. Attaches the certificate to the application
5. Configures all required Graph API permissions
6. Grants admin consent
7. Verifies certificate authentication works
8. Confirms the tenant ID matches

##### Prerequisites for Setup Script

```powershell
# Install required modules
Install-Module Microsoft.Graph.Authentication -Scope CurrentUser -Force
Install-Module Microsoft.Graph.Applications -Scope CurrentUser -Force
```

##### Basic Setup

```powershell
# Run the setup script with your tenant ID
./Setup-IntuneHydrationApp.ps1 -TenantId "00000000-0000-0000-0000-000000000000"
```

This will:
- Open a browser for admin authentication
- Create app registration "Intune-Hydration-Kit"
- Generate a 2-year self-signed certificate
- Configure all permissions and grant consent
- Output the settings.json configuration to use

##### Setup Script Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-TenantId` | Azure AD tenant ID (GUID) | Required |
| `-ApplicationName` | Display name for the app | `Intune-Hydration-Kit` |
| `-CertificateSubject` | Certificate subject name | `CN=Intune-Hydration-Kit` |
| `-CertificateValidityMonths` | Certificate validity (1-60 months) | `24` |
| `-ExistingCertificateThumbprint` | Use existing certificate | None |
| `-NonExportable` | Create non-exportable private key | `false` |
| `-ExportCertificate` | Export .cer and .pfx files | `false` |
| `-Force` | Skip confirmation prompts | `false` |

##### Advanced Setup Examples

```powershell
# Non-exportable certificate (stronger security, cannot be backed up)
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId -NonExportable -Force

# Custom certificate subject and 3-year validity
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId `
    -CertificateSubject "CN=Intune-Hydration-Prod" `
    -CertificateValidityMonths 36

# Use existing certificate from certificate store
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId `
    -ExistingCertificateThumbprint "1A2B3C4D5E6F..."

# Export certificate files for backup/migration
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId -ExportCertificate

# Full automation (no prompts)
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId -Force
```

##### Setup Script Output

After successful setup, the script outputs configuration for `settings.json`:

```
=============================================
  Setup Complete
=============================================

[+] Application Name: Intune-Hydration-Kit
[+] Application ID (ClientId): a1b2c3d4-e5f6-7890-abcd-ef1234567890
[+] Tenant ID: 00000000-0000-0000-0000-000000000000
[+] Certificate Subject: CN=Intune-Hydration-Kit
[+] Certificate Thumbprint: ABC123DEF456789...
[+] Certificate Expires: 12/16/2027 10:30:00 AM

Update your settings.json with the following:

{
    "tenant": {
        "tenantId": "00000000-0000-0000-0000-000000000000"
    },
    "authentication": {
        "mode": "certificate",
        "clientId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "certificateThumbprint": "ABC123DEF456789...",
        "environment": "Global"
    }
}

[i] Certificate is stored in: Cert:\CurrentUser\My\ABC123DEF456789...
```

#### Configure Settings for Certificate Authentication

##### Using Certificate Thumbprint (Recommended)

```json
"authentication": {
    "mode": "certificate",
    "clientId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "certificateThumbprint": "ABC123DEF456789...",
    "environment": "Global"
}
```

##### Using Certificate Subject

Alternatively, specify the certificate by subject name (uses the most recent valid certificate):

```json
"authentication": {
    "mode": "certificate",
    "clientId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "certificateSubject": "CN=Intune-Hydration-Kit",
    "environment": "Global"
}
```

#### Certificate Storage Locations

The kit searches for certificates in this order:
1. `Cert:\CurrentUser\My` - Current user's personal store
2. `Cert:\LocalMachine\My` - Local machine's personal store

For service accounts or CI/CD runners, install the certificate to `LocalMachine\My`.

#### Manual Certificate Management

##### View Certificate in Store

```powershell
# List certificates with matching subject
Get-ChildItem -Path Cert:\CurrentUser\My |
    Where-Object { $_.Subject -like "*Intune-Hydration*" } |
    Select-Object Subject, Thumbprint, NotAfter

# Check certificate details
$cert = Get-ChildItem -Path Cert:\CurrentUser\My\<thumbprint>
$cert | Format-List Subject, Issuer, NotBefore, NotAfter, Thumbprint
```

##### Export Certificate for Backup

```powershell
$cert = Get-ChildItem -Path Cert:\CurrentUser\My\<thumbprint>

# Export public key (.cer) - safe to share
Export-Certificate -Cert $cert -FilePath ./Intune-Hydration-Kit.cer -Type CERT

# Export with private key (.pfx) - keep secure!
$password = Read-Host -Prompt "PFX Password" -AsSecureString
Export-PfxCertificate -Cert $cert -FilePath ./Intune-Hydration-Kit.pfx -Password $password
```

##### Import Certificate to Another Machine

```powershell
# Import to CurrentUser store
$password = Read-Host -Prompt "PFX Password" -AsSecureString
Import-PfxCertificate -FilePath ./Intune-Hydration-Kit.pfx `
    -CertStoreLocation Cert:\CurrentUser\My `
    -Password $password

# Import to LocalMachine store (requires admin)
Import-PfxCertificate -FilePath ./Intune-Hydration-Kit.pfx `
    -CertStoreLocation Cert:\LocalMachine\My `
    -Password $password
```

##### Renew Certificate Before Expiration

```powershell
# Generate new certificate with same subject
$newCert = New-SelfSignedCertificate `
    -Subject "CN=Intune-Hydration-Kit" `
    -CertStoreLocation Cert:\CurrentUser\My `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -NotAfter (Get-Date).AddYears(2)

# Update the app registration with new certificate
# (Run setup script again or manually update via Azure Portal)
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId `
    -ExistingCertificateThumbprint $newCert.Thumbprint
```

#### Tenant ID Confirmation

Certificate authentication includes automatic tenant ID verification:

1. After connecting, the kit retrieves the connected tenant ID from `Get-MgContext`
2. If you provided a GUID as `tenantId`, it verifies the connected tenant matches
3. If there's a mismatch, the connection is terminated with an error
4. The organization name is displayed to confirm the correct tenant

```
Connecting to Global environment (https://graph.microsoft.com)
Using certificate: CN=Intune-Hydration-Kit (Thumbprint: ABC123...)
Connecting with certificate authentication...
Successfully connected to tenant: ********-****-****-****-********7890 (Global)
Authentication mode: Certificate
Client ID: a1b2c3d4-e5f6-7890-abcd-ef1234567890
Organization: Contoso Corporation
```

---

### Client Secret Authentication (Not Recommended)

> **Warning:** Client secrets are less secure than certificates. Use `Setup-IntuneHydrationApp.ps1`
> to configure certificate authentication instead. Client secrets expire, can be leaked in logs,
> and cannot be hardware-protected.

If you must use client secrets for legacy compatibility:

```json
"authentication": {
    "mode": "clientSecret",
    "clientId": "00000000-0000-0000-0000-000000000000",
    "clientSecret": "your-client-secret-value",
    "environment": "Global"
}
```

**Never commit client secrets to source control.** Use environment variables:

```powershell
$settings = Get-Content ./settings.json | ConvertFrom-Json
$settings.authentication.clientSecret = $env:INTUNE_CLIENT_SECRET
$settings | ConvertTo-Json -Depth 10 | Set-Content ./settings.runtime.json
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.runtime.json
```

### Supported Cloud Environments

| Environment | Graph Endpoint | Use Case |
|-------------|----------------|----------|
| `Global` | `graph.microsoft.com` | Commercial/Public cloud |
| `USGov` | `graph.microsoft.us` | US Government GCC High |
| `USGovDoD` | `dod-graph.microsoft.us` | US Government DoD |
| `Germany` | `graph.microsoft.de` | Germany sovereign cloud |
| `China` | `microsoftgraph.chinacloudapi.cn` | China (21Vianet) |

```json
"authentication": {
    "mode": "interactive",
    "environment": "USGov"
}
```

---

## Execution

### Dry-Run Mode (Always Run First)

Preview all changes without modifying the tenant:

```powershell
# Using -WhatIf parameter
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json -WhatIf

# Or set dryRun in settings.json
"options": {
    "dryRun": true,
    "create": true
}
```

Sample dry-run output:
```
▶ Step 1: Authenticating to Microsoft Graph
  [i] Connecting to Global environment (https://graph.microsoft.com)
  [i] Successfully connected to tenant: ********-****-****-****-********7890 (Global)

▶ Step 2: Running pre-flight checks
  [i] Connected to: Contoso Corporation
  [i] Found Intune license: INTUNE_A
  [i] All required permission scopes are present

▶ Step 3: Creating Dynamic Groups
  [i] WouldCreate: Windows Devices - All
  [i] WouldCreate: macOS Devices - All
  ...

---------------- Summary ----------------
Would Create: 123 | Would Update: 0 | Would Delete: 0 | Skipped: 0 | Failed: 0
```

### Live Execution

```powershell
# Execute hydration
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json
```

### Selective Import

Only import specific configuration types:

```json
"imports": {
    "openIntuneBaseline": false,
    "complianceTemplates": true,
    "appProtection": false,
    "notificationTemplates": false,
    "enrollmentProfiles": false,
    "dynamicGroups": true,
    "deviceFilters": true,
    "conditionalAccess": false
}
```

---

## Execution Flow

The orchestrator script (`Invoke-IntuneHydration.ps1`) executes the following steps:

```
Step 1: Authenticate to Microsoft Graph
        └── Connect-IntuneHydration

Step 2: Pre-flight checks
        └── Test-IntunePrerequisites
            ├── Verify Intune license
            └── Validate Graph permission scopes

Step 3: Dynamic Groups (if enabled)
        └── New-IntuneDynamicGroup
            └── Templates/DynamicGroups/*.json

Step 4: Device Filters (if enabled)
        └── Import-IntuneDeviceFilter

Step 5: OpenIntuneBaseline (if enabled)
        └── Import-IntuneBaseline
            ├── Get-OpenIntuneBaseline (downloads from GitHub)
            └── Imports 70+ policies via Graph API

Step 6: Compliance Templates (if enabled)
        └── Import-IntuneCompliancePolicy
            └── Templates/Compliance/*.json

Step 7: Notification Templates (if enabled)
        └── Import-IntuneNotificationTemplate

Step 8: App Protection Policies (if enabled)
        └── Import-IntuneAppProtectionPolicy
            └── Templates/AppProtection/*.json

Step 9: Enrollment Profiles (if enabled)
        └── Import-IntuneEnrollmentProfile
            └── Templates/Enrollment/*.json

Step 10: Conditional Access (if enabled)
         └── Import-IntuneConditionalAccessPolicy
             └── Templates/ConditionalAccess/*.json
             └── All policies created in DISABLED state

Step 11: Generate Summary Report
         └── Get-ResultSummary
             ├── Reports/Hydration-Summary.md
             └── Reports/Hydration-Summary.json
```

### Result Tracking

Each operation returns a standardized result object:

```powershell
# Result object structure
[PSCustomObject]@{
    Name      = "Windows Compliance Policy"
    Action    = "Created"           # Created|Updated|Deleted|Skipped|Failed|WouldCreate|WouldDelete
    Status    = "Success"           # Success|Already exists|DryRun|<error message>
    Timestamp = "2024-11-27 14:30:52"
    Type      = "CompliancePolicy"
    Id        = "abc123-..."        # Graph object ID (if created)
}
```

---

## Logging

### Log File Location

Logs are written to `./Logs/` with timestamped filenames:

```
Logs/
├── hydration-20241127-143052.log
├── hydration-20241127-151230.log
└── ...
```

### Log Format

```
[2024-11-27 14:30:52] [Info] === Intune Hydration Kit Started ===
[2024-11-27 14:30:52] [Info] Loaded settings for tenant: ********-****-****-****-********7890
[2024-11-27 14:30:52] [Warning] Running in DRY-RUN mode - no changes will be made
[2024-11-27 14:30:53] [Info] Step 1: Authenticating to Microsoft Graph
[2024-11-27 14:30:55] [Info] Step 2: Running pre-flight checks
[2024-11-27 14:30:56] [Info] Step 3: Creating Dynamic Groups
[2024-11-27 14:30:56] [Info]   Created: Windows Devices - All
[2024-11-27 14:30:57] [Info]   Skipped: macOS Devices - All
[2024-11-27 14:30:58] [Warning]   Failed: Linux Devices - All - Insufficient privileges
```

### Log Levels

| Level | Icon | Color | Description |
|-------|------|-------|-------------|
| `Info` | `[i]` | Cyan | Normal operations |
| `Warning` | `[!]` | Yellow | Non-fatal issues, skipped items |
| `Error` | `[x]` | Red | Fatal errors |
| `Debug` | `[~]` | Gray | Verbose details (requires `verbose: true`) |

### Enable Verbose Logging

```json
"options": {
    "verbose": true
}
```

Or via PowerShell preference:

```powershell
$VerbosePreference = "Continue"
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json
```

### Programmatic Log Access

```powershell
# Read current session log
$logFile = Get-ChildItem ./Logs -Filter "hydration-*.log" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1

Get-Content $logFile.FullName

# Filter for errors only
Get-Content $logFile.FullName | Where-Object { $_ -match '\[Error\]|\[Warning\]' }

# Parse log entries
Get-Content $logFile.FullName | ForEach-Object {
    if ($_ -match '^\[(.+?)\] \[(.+?)\] (.+)$') {
        [PSCustomObject]@{
            Timestamp = $Matches[1]
            Level     = $Matches[2]
            Message   = $Matches[3]
        }
    }
}
```

---

## Reports

### Generated Reports

After each execution, reports are written to `./Reports/`:

```
Reports/
├── Hydration-Summary.md    # Human-readable markdown
└── Hydration-Summary.json  # Machine-readable JSON
```

### Markdown Report Structure

```markdown
# Intune Hydration Summary

**Generated:** 2024-11-27 14:35:22
**Tenant:** 00000000-0000-0000-0000-000000000000
**Environment:** Global
**Mode:** Live

## Summary

| Metric | Count |
|--------|-------|
| Total Operations | 127 |
| Created | 115 |
| Updated | 0 |
| Skipped | 10 |
| Would Create | 0 |
| Would Update | 0 |
| Failed | 2 |

## Details by Type

### DynamicGroup
- Created: 12
- Skipped: 0
- Failed: 0

### CompliancePolicy
- Created: 10
- Skipped: 0
- Failed: 0
...
```

### JSON Report Structure

```json
{
    "Timestamp": "2024-11-27 14:35:22",
    "Tenant": "00000000-0000-0000-0000-000000000000",
    "Environment": "Global",
    "Mode": "Live",
    "Summary": {
        "Created": 115,
        "Updated": 0,
        "Deleted": 0,
        "Skipped": 10,
        "WouldCreate": 0,
        "WouldUpdate": 0,
        "WouldDelete": 0,
        "Failed": 2
    },
    "Results": [
        {
            "Name": "Windows Devices - All",
            "Action": "Created",
            "Status": "Success",
            "Timestamp": "2024-11-27 14:30:56",
            "Type": "DynamicGroup",
            "Id": "abc123-def456-..."
        }
    ]
}
```

### Processing Reports Programmatically

```powershell
# Load JSON report
$report = Get-Content ./Reports/Hydration-Summary.json | ConvertFrom-Json

# Get failed operations
$report.Results | Where-Object { $_.Action -eq 'Failed' }

# Group by type
$report.Results | Group-Object Type | ForEach-Object {
    [PSCustomObject]@{
        Type    = $_.Name
        Count   = $_.Count
        Created = ($_.Group | Where-Object Action -eq 'Created').Count
        Failed  = ($_.Group | Where-Object Action -eq 'Failed').Count
    }
}

# Export failures to CSV for tracking
$report.Results |
    Where-Object { $_.Action -eq 'Failed' } |
    Export-Csv -Path ./failed-items.csv -NoTypeInformation
```

---

## Cleanup and Deletion

### Safety Mechanism

The kit uses a hydration marker in object descriptions to identify objects it created:

```
Imported by Intune-Hydration-Kit
```

**Only objects with this marker can be deleted by the kit.** Manually created objects with the same name are never affected.

### Delete Mode Configuration

```json
"options": {
    "dryRun": false,
    "create": false,
    "delete": true
}
```

### Preview Deletion

```powershell
# Always preview first
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json -WhatIf
```

Output:
```
▶ Step 3: Deleting Dynamic Groups
  [i] WouldDelete: Windows Devices - All
  [i] WouldDelete: macOS Devices - All
  [i] Skipping 'Custom Group' - not created by Intune-Hydration-Kit
```

### Execute Deletion

```powershell
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json
```

### Conditional Access Deletion Protection

CA policies have additional protection:
- Must have hydration marker in description
- **Must be in `disabled` state** to be deleted
- Enabled CA policies are never deleted (prevents accidental lockout)

### Selective Cleanup

Delete only specific object types:

```json
"imports": {
    "openIntuneBaseline": false,
    "complianceTemplates": false,
    "appProtection": false,
    "notificationTemplates": false,
    "enrollmentProfiles": false,
    "dynamicGroups": true,      // Only delete dynamic groups
    "deviceFilters": true,      // Only delete device filters
    "conditionalAccess": false
}
```

---

## Troubleshooting

### Common Errors

#### "The term 'Invoke-MgGraphRequest' is not recognized"

```powershell
# Cause: Microsoft.Graph.Authentication module not installed
Install-Module Microsoft.Graph.Authentication -Force -Scope CurrentUser
Import-Module Microsoft.Graph.Authentication
```

#### "Insufficient privileges to complete the operation"

```powershell
# Check current scopes
$context = Get-MgContext
$context.Scopes

# Required scopes
$requiredScopes = @(
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

# Find missing scopes
$missing = $requiredScopes | Where-Object { $_ -notin $context.Scopes }
Write-Host "Missing scopes: $($missing -join ', ')"

# Reconnect with all scopes
Disconnect-MgGraph
Connect-MgGraph -Scopes $requiredScopes -TenantId "your-tenant-id"
```

#### "No active Intune license found"

```powershell
# Check tenant licenses via Graph
$skus = Invoke-MgGraphRequest -Method GET -Uri "beta/subscribedSkus"
$skus.value | ForEach-Object {
    $_.servicePlans | Where-Object {
        $_.servicePlanName -match 'INTUNE|EMS'
    } | Select-Object servicePlanName, provisioningStatus
}
```

#### "Only one of 'create' or 'delete' options can be true"

The settings file has both `create` and `delete` set to `true`. These are mutually exclusive:

```json
// CREATE mode
"options": { "create": true, "delete": false }

// DELETE mode
"options": { "create": false, "delete": true }
```

#### Graph API Rate Limiting (429 Too Many Requests)

The kit includes 100ms delays between operations, but bulk imports may hit throttling:

```powershell
# Error in log
[Warning] Failed: Policy Name - {"error":{"code":"TooManyRequests"...}}

# Solution: Wait and retry
Start-Sleep -Seconds 60
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json
```

#### "Request body has invalid JSON"

Usually caused by templates with incorrect schema. Validate template JSON:

```powershell
# Test JSON validity
$templatePath = "./Templates/Compliance/Windows-Compliance-Policy.json"
try {
    Get-Content $templatePath -Raw | ConvertFrom-Json
    Write-Host "Valid JSON"
} catch {
    Write-Error "Invalid JSON: $_"
}
```

#### Certificate Authentication Errors

##### "Certificate with thumbprint 'X' not found"

```powershell
# List all certificates in the store
Get-ChildItem -Path Cert:\CurrentUser\My | Select-Object Subject, Thumbprint, NotAfter

# Check if certificate exists with correct thumbprint
Get-ChildItem -Path Cert:\CurrentUser\My\<thumbprint>

# If using subject-based lookup, verify exact subject match
Get-ChildItem -Path Cert:\CurrentUser\My |
    Where-Object { $_.Subject -eq 'CN=Intune-Hydration-Kit' }
```

##### "Tenant ID mismatch"

The certificate is valid but authenticated to the wrong tenant:

```powershell
# The error shows:
# Tenant ID mismatch! Expected: <your-tenant>, Connected: <wrong-tenant>

# Verify the app registration exists in the correct tenant
# Re-run setup script if needed
./Setup-IntuneHydrationApp.ps1 -TenantId "correct-tenant-id"
```

##### "AADSTS700027: Client assertion contains an invalid signature"

The certificate attached to the app registration doesn't match the local certificate:

```powershell
# Get the local certificate thumbprint
$cert = Get-ChildItem -Path Cert:\CurrentUser\My |
    Where-Object { $_.Subject -eq 'CN=Intune-Hydration-Kit' } |
    Select-Object -First 1
$cert.Thumbprint

# Re-attach certificate to app registration
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId `
    -ExistingCertificateThumbprint $cert.Thumbprint
```

##### "Certificate has expired"

```powershell
# Check certificate expiration
Get-ChildItem -Path Cert:\CurrentUser\My |
    Where-Object { $_.Subject -like "*Intune-Hydration*" } |
    Select-Object Subject, NotAfter, @{N='DaysUntilExpiry';E={($_.NotAfter - (Get-Date)).Days}}

# Generate new certificate
$newCert = New-SelfSignedCertificate `
    -Subject "CN=Intune-Hydration-Kit" `
    -CertStoreLocation Cert:\CurrentUser\My `
    -KeyExportPolicy Exportable `
    -KeySpec Signature `
    -KeyLength 2048 `
    -NotAfter (Get-Date).AddYears(2)

# Update app registration with new certificate
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId `
    -ExistingCertificateThumbprint $newCert.Thumbprint
```

##### Certificate not found in CI/CD pipeline

```powershell
# Verify certificate was imported correctly
Get-ChildItem -Path Cert:\CurrentUser\My | Select-Object Subject, Thumbprint

# Check if base64 decoding worked
$pfxBytes = [System.Convert]::FromBase64String($env:CERT_PFX_BASE64)
Write-Host "PFX size: $($pfxBytes.Length) bytes"  # Should be > 0
```

### Debug Graph API Calls

Enable verbose mode to see request/response details:

```powershell
$VerbosePreference = "Continue"
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json -WhatIf
```

### Test Individual Functions

```powershell
# Import module
Import-Module ./IntuneHydrationKit.psd1 -Force

# Manually authenticate
Connect-IntuneHydration -TenantId "your-tenant-id" -Interactive

# Run prerequisite check
Test-IntunePrerequisites

# Test single import function
Import-IntuneCompliancePolicy -WhatIf

# Check connection state
Get-MgContext
```

### Validate Existing Objects

```powershell
# Check if an object was created by the kit
$groups = Invoke-MgGraphRequest -Method GET -Uri "beta/groups?`$filter=groupTypes/any(c:c eq 'DynamicMembership')&`$select=displayName,description"

$groups.value | ForEach-Object {
    [PSCustomObject]@{
        Name        = $_.displayName
        HydrationKit = $_.description -match 'Imported by Intune-Hydration-Kit'
    }
}
```

---

## Advanced Scenarios

### CI/CD Pipeline Integration

#### Certificate Setup for CI/CD

Before using CI/CD pipelines, you must:

1. Run `Setup-IntuneHydrationApp.ps1` to create the app registration and certificate
2. Export the certificate with `-ExportCertificate` flag
3. Store the PFX file securely (Azure Key Vault, GitHub Secrets as base64, etc.)

```powershell
# Generate certificate and export for CI/CD use
./Setup-IntuneHydrationApp.ps1 -TenantId $tenantId -ExportCertificate -Force

# Convert PFX to base64 for storage in secrets
$pfxBytes = [System.IO.File]::ReadAllBytes("./Intune-Hydration-Kit.pfx")
$pfxBase64 = [System.Convert]::ToBase64String($pfxBytes)
$pfxBase64 | Set-Clipboard  # Paste into CI/CD secret
```

#### Azure DevOps YAML Pipeline (Certificate Auth)

```yaml
trigger:
  - main

pool:
  vmImage: 'windows-latest'

variables:
  - group: intune-hydration-secrets  # Contains TENANT_ID, CLIENT_ID, CERT_PFX_BASE64, CERT_PASSWORD

steps:
  - task: PowerShell@2
    displayName: 'Install Prerequisites'
    inputs:
      targetType: 'inline'
      script: |
        Install-Module Microsoft.Graph.Authentication -Force -Scope CurrentUser
      pwsh: true

  - task: PowerShell@2
    displayName: 'Import Certificate'
    inputs:
      targetType: 'inline'
      script: |
        # Decode and import certificate from base64
        $pfxBytes = [System.Convert]::FromBase64String("$(CERT_PFX_BASE64)")
        $pfxPath = "$env:TEMP\hydration-cert.pfx"
        [System.IO.File]::WriteAllBytes($pfxPath, $pfxBytes)

        $password = ConvertTo-SecureString -String "$(CERT_PASSWORD)" -AsPlainText -Force
        $cert = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $password

        # Export thumbprint for next step
        Write-Host "##vso[task.setvariable variable=CERT_THUMBPRINT]$($cert.Thumbprint)"

        # Clean up PFX file
        Remove-Item -Path $pfxPath -Force
      pwsh: true

  - task: PowerShell@2
    displayName: 'Run Intune Hydration'
    inputs:
      targetType: 'inline'
      script: |
        # Build settings with certificate authentication
        $settings = @{
            tenant = @{
                tenantId = "$(TENANT_ID)"
                tenantName = "pipeline"
            }
            authentication = @{
                mode = "certificate"
                clientId = "$(CLIENT_ID)"
                certificateThumbprint = "$(CERT_THUMBPRINT)"
                environment = "Global"
            }
            options = @{
                dryRun = $false
                create = $true
                delete = $false
                verbose = $true
            }
            imports = @{
                openIntuneBaseline = $true
                complianceTemplates = $true
                appProtection = $true
                notificationTemplates = $true
                enrollmentProfiles = $true
                dynamicGroups = $true
                deviceFilters = $true
                conditionalAccess = $true
            }
            reporting = @{
                outputPath = "./Reports"
                formats = @("markdown", "json")
            }
        }

        $settings | ConvertTo-Json -Depth 10 | Set-Content ./settings.pipeline.json

        Import-Module ./IntuneHydrationKit.psd1 -Force
        ./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.pipeline.json
      pwsh: true

  - task: PublishBuildArtifacts@1
    displayName: 'Publish Reports'
    inputs:
      PathtoPublish: './Reports'
      ArtifactName: 'hydration-reports'
    condition: always()
```

#### GitHub Actions Workflow (Certificate Auth)

```yaml
name: Intune Hydration

on:
  workflow_dispatch:
    inputs:
      dry_run:
        description: 'Dry run mode'
        required: true
        default: 'true'
        type: choice
        options:
          - 'true'
          - 'false'

jobs:
  hydrate:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Prerequisites
        shell: pwsh
        run: |
          Install-Module Microsoft.Graph.Authentication -Force -Scope CurrentUser

      - name: Import Certificate
        shell: pwsh
        env:
          CERT_PFX_BASE64: ${{ secrets.CERT_PFX_BASE64 }}
          CERT_PASSWORD: ${{ secrets.CERT_PASSWORD }}
        run: |
          # Decode and import certificate
          $pfxBytes = [System.Convert]::FromBase64String($env:CERT_PFX_BASE64)
          $pfxPath = "$env:TEMP\hydration-cert.pfx"
          [System.IO.File]::WriteAllBytes($pfxPath, $pfxBytes)

          $password = ConvertTo-SecureString -String $env:CERT_PASSWORD -AsPlainText -Force
          $cert = Import-PfxCertificate -FilePath $pfxPath -CertStoreLocation Cert:\CurrentUser\My -Password $password

          # Set output for next step
          "CERT_THUMBPRINT=$($cert.Thumbprint)" | Out-File -FilePath $env:GITHUB_ENV -Append

          # Clean up
          Remove-Item -Path $pfxPath -Force

      - name: Run Hydration
        shell: pwsh
        env:
          TENANT_ID: ${{ secrets.TENANT_ID }}
          CLIENT_ID: ${{ secrets.CLIENT_ID }}
        run: |
          $settings = Get-Content ./settings.example.json | ConvertFrom-Json
          $settings.tenant.tenantId = $env:TENANT_ID
          $settings.authentication.mode = "certificate"
          $settings.authentication.clientId = $env:CLIENT_ID
          $settings.authentication.certificateThumbprint = $env:CERT_THUMBPRINT
          $settings.options.dryRun = [bool]::Parse("${{ inputs.dry_run }}")

          $settings | ConvertTo-Json -Depth 10 | Set-Content ./settings.json

          Import-Module ./IntuneHydrationKit.psd1 -Force
          ./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json

      - uses: actions/upload-artifact@v4
        with:
          name: hydration-reports
          path: ./Reports/
        if: always()
```

#### Required CI/CD Secrets

| Secret | Description |
|--------|-------------|
| `TENANT_ID` | Azure AD tenant ID (GUID) |
| `CLIENT_ID` | Application (client) ID from app registration |
| `CERT_PFX_BASE64` | Base64-encoded PFX certificate file |
| `CERT_PASSWORD` | Password used when exporting the PFX |

### Multi-Tenant Deployment

```powershell
# Define tenant configurations
$tenants = @(
    @{ Id = "tenant1-guid"; Name = "Tenant 1"; Env = "Global" },
    @{ Id = "tenant2-guid"; Name = "Tenant 2"; Env = "Global" },
    @{ Id = "tenant3-guid"; Name = "Tenant 3 (GCC)"; Env = "USGov" }
)

# Base settings template
$baseSettings = Get-Content ./settings.example.json | ConvertFrom-Json

foreach ($tenant in $tenants) {
    Write-Host "Processing: $($tenant.Name)" -ForegroundColor Cyan

    # Clone and customize settings
    $settings = $baseSettings | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $settings.tenant.tenantId = $tenant.Id
    $settings.tenant.tenantName = $tenant.Name
    $settings.authentication.environment = $tenant.Env

    # Write tenant-specific settings
    $settingsPath = "./settings-$($tenant.Id).json"
    $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath

    # Execute hydration
    try {
        ./Invoke-IntuneHydration.ps1 -SettingsPath $settingsPath
        Write-Host "Completed: $($tenant.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed: $($tenant.Name) - $_" -ForegroundColor Red
    }

    # Disconnect before next tenant
    Disconnect-MgGraph -ErrorAction SilentlyContinue
}
```

### Custom Template Development

Create custom policy templates following Graph API schema:

```powershell
# Export existing policy as template
$policyId = "existing-policy-id"
$policy = Invoke-MgGraphRequest -Method GET -Uri "beta/deviceManagement/deviceCompliancePolicies/$policyId"

# Remove read-only properties
$readOnlyProps = @('id', 'createdDateTime', 'lastModifiedDateTime', 'version',
                   'assignments', 'scheduledActionsForRule.scheduledActionConfigurations.id')

function Remove-Properties {
    param($obj, $props)
    foreach ($prop in $props) {
        $obj.PSObject.Properties.Remove($prop)
    }
}

Remove-Properties -obj $policy -props $readOnlyProps

# Save as template
$policy | ConvertTo-Json -Depth 20 | Set-Content "./Templates/Compliance/Custom-Policy.json"
```

### Exit Codes

The orchestrator returns specific exit codes for automation:

| Code | Meaning |
|------|---------|
| `0` | Success (all operations completed) |
| `1` | Failure (one or more operations failed) |

```powershell
# Check exit code in scripts
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json
if ($LASTEXITCODE -ne 0) {
    Write-Error "Hydration failed with exit code: $LASTEXITCODE"
    # Send alert, roll back, etc.
}
```

---

## Quick Reference

### Command Cheat Sheet

```powershell
# === Setup ===
# Create app registration with certificate (first-time setup)
./Setup-IntuneHydrationApp.ps1 -TenantId "tenant-id"

# Create with non-exportable certificate (more secure)
./Setup-IntuneHydrationApp.ps1 -TenantId "tenant-id" -NonExportable -Force

# Export certificate for CI/CD
./Setup-IntuneHydrationApp.ps1 -TenantId "tenant-id" -ExportCertificate

# === Execution ===
# Full dry-run
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json -WhatIf

# Live execution
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json

# Verbose mode
$VerbosePreference = "Continue"
./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json

# === Connection ===
# Check connection
Get-MgContext

# Manual authentication - interactive
Connect-IntuneHydration -TenantId "tenant-id" -Interactive

# Manual authentication - certificate
Connect-IntuneHydration -TenantId "tenant-id" -ClientId "app-id" -CertificateThumbprint "ABC123..."

# Manual authentication - certificate by subject
Connect-IntuneHydration -TenantId "tenant-id" -ClientId "app-id" -CertificateSubject "CN=Intune-Hydration-Kit"

# === Diagnostics ===
# Check prerequisites
Test-IntunePrerequisites

# View latest log
Get-Content (Get-ChildItem ./Logs -Filter "*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1)

# Parse JSON report
(Get-Content ./Reports/Hydration-Summary.json | ConvertFrom-Json).Summary

# === Certificate Management ===
# List certificates
Get-ChildItem -Path Cert:\CurrentUser\My | Where-Object { $_.Subject -like "*Intune*" }

# Check certificate expiration
Get-ChildItem -Path Cert:\CurrentUser\My\<thumbprint> | Select-Object Subject, NotAfter
```

### Settings Quick Reference

```json
// Interactive authentication
{
    "authentication": {
        "mode": "interactive",
        "environment": "Global"
    }
}

// Certificate authentication (recommended)
{
    "authentication": {
        "mode": "certificate",
        "clientId": "app-client-id",
        "certificateThumbprint": "ABC123...",
        "environment": "Global"
    }
}

// Certificate authentication (by subject)
{
    "authentication": {
        "mode": "certificate",
        "clientId": "app-client-id",
        "certificateSubject": "CN=Intune-Hydration-Kit",
        "environment": "Global"
    }
}

// Operation modes
{ "options": { "dryRun": true, "create": true, "delete": false, "verbose": true } }   // Dry-run
{ "options": { "dryRun": false, "create": true, "delete": false, "verbose": false } } // Live
{ "options": { "dryRun": false, "create": false, "delete": true, "verbose": true } }  // Delete
```
