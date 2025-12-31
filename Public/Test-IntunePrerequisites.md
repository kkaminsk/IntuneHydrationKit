# Test-IntunePrerequisites

## Synopsis

Validates Intune tenant prerequisites.

## Description

Performs a comprehensive check of prerequisites required for the Intune Hydration Kit to function correctly. Validates Intune licensing and required Microsoft Graph API permission scopes.

## Syntax

```powershell
Test-IntunePrerequisites
```

## Parameters

This function takes no parameters.

## Outputs

**Boolean** - Returns `$true` if all prerequisites pass. Throws an exception if any checks fail.

## Prerequisite Checks

### License Validation

Checks for active Intune-related service plans:

| Service Plan | Description |
|--------------|-------------|
| `INTUNE_A` | Intune Plan 1 |
| `INTUNE_EDU` | Intune for Education |
| `INTUNE_SMBIZ` | Intune Small Business |
| `AAD_PREMIUM` | Azure AD Premium |
| `EMSPREMIUM` | Enterprise Mobility + Security |

### Required Permission Scopes

Validates that the current Graph connection has these scopes:

| Scope | Purpose |
|-------|---------|
| `DeviceManagementConfiguration.ReadWrite.All` | Configuration policies |
| `DeviceManagementServiceConfig.ReadWrite.All` | Service configuration |
| `DeviceManagementManagedDevices.ReadWrite.All` | Device management |
| `DeviceManagementScripts.ReadWrite.All` | PowerShell scripts |
| `DeviceManagementApps.ReadWrite.All` | App management |
| `Group.ReadWrite.All` | Dynamic groups |
| `Policy.Read.All` | Read policies |
| `Policy.ReadWrite.ConditionalAccess` | Conditional Access |
| `Application.Read.All` | Application read |
| `Directory.ReadWrite.All` | Directory operations |

## Examples

### Example 1: Check prerequisites

```powershell
Test-IntunePrerequisites
```

Validates all prerequisites and outputs status messages.

### Example 2: Use in automation

```powershell
try {
    Connect-IntuneHydration -TenantId "contoso.onmicrosoft.com" -Interactive
    Test-IntunePrerequisites

    # Proceed with hydration
    ./Invoke-IntuneHydration.ps1 -SettingsPath ./settings.json
}
catch {
    Write-Error "Prerequisites not met: $_"
    exit 1
}
```

### Example 3: Check before running hydration

```powershell
if (Test-IntunePrerequisites) {
    Write-Host "All checks passed, proceeding..."
    Import-IntuneBaseline
}
```

## Output Messages

The function provides console feedback during validation:

```
Validating Intune prerequisites...
Connected to: Contoso Corporation
Found Intune license: INTUNE_A
All required permission scopes are present
All prerequisite checks passed
```

## Error Scenarios

| Issue | Message |
|-------|---------|
| No Intune license | "No active Intune license found" |
| Missing scopes | "Missing required permission scopes: [scope list]" |
| Not connected | "Not connected to Microsoft Graph" |

## Related Functions

- [Connect-IntuneHydration](Connect-IntuneHydration.md)
- [Import-HydrationSettings](Import-HydrationSettings.md)
