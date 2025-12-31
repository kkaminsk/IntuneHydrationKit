# Import-IntuneBaseline

## Synopsis

Imports OpenIntuneBaseline policies into Microsoft Intune.

## Description

Downloads the OpenIntuneBaseline repository from GitHub and imports all baseline security policies into Microsoft Intune via the Graph API. Supports multiple policy types including Settings Catalog, Device Configurations, Compliance Policies, and App Protection Policies.

The OpenIntuneBaseline is a community-maintained collection of security baselines organized by operating system (Windows, macOS, iOS, Android).

## Syntax

```powershell
Import-IntuneBaseline
    [-BaselinePath <String>]
    [-TenantId <String>]
    [-ImportMode <String>]
    [-RemoveExisting]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -BaselinePath

Path to the OpenIntuneBaseline directory. If not specified or not found, the baseline will be automatically downloaded from GitHub.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | Downloads from GitHub |

### -TenantId

Target tenant ID for import. Uses the connected tenant if not specified.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | Connected tenant ID |

### -ImportMode

Controls behavior when policies already exist.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `SkipIfExists` |
| Valid Values | `SkipIfExists` |

### -RemoveExisting

When specified, removes existing baseline policies that were created by the Hydration Kit.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

## Outputs

**Array** - Returns an array of `HydrationResult` objects for each policy processed.

## Supported Policy Types

The function maps OpenIntuneBaseline folder structures to Graph API endpoints:

| Folder Name | Graph API Endpoint |
|-------------|-------------------|
| NativeImport | deviceManagement/configurationPolicies |
| Settings Catalog | deviceManagement/configurationPolicies |
| Compliance / Compliance Policies | deviceManagement/deviceCompliancePolicies |
| Configuration Profiles / Device Configuration | deviceManagement/deviceConfigurations |
| Administrative Templates | deviceManagement/groupPolicyConfigurations |
| Endpoint Security | deviceManagement/intents |
| App Protection / App Protection Policies | deviceAppManagement/managedAppPolicies |
| Scripts | deviceManagement/deviceManagementScripts |
| Proactive Remediations | deviceManagement/deviceHealthScripts |
| Windows Autopilot | deviceManagement/windowsAutopilotDeploymentProfiles |

## Examples

### Example 1: Import baselines with auto-download

```powershell
Import-IntuneBaseline
```

Downloads OpenIntuneBaseline from GitHub and imports all policies.

### Example 2: Import from local copy

```powershell
Import-IntuneBaseline -BaselinePath "C:\Baselines\OpenIntuneBaseline"
```

Imports policies from a local copy of the baseline repository.

### Example 3: Preview changes

```powershell
Import-IntuneBaseline -WhatIf
```

Shows what policies would be imported without making changes.

### Example 4: Remove all Hydration Kit baselines

```powershell
Import-IntuneBaseline -RemoveExisting
```

Removes all baseline policies previously created by the Hydration Kit.

## Processing Flow

1. Downloads OpenIntuneBaseline if no path provided
2. Pre-fetches existing policies to optimize API calls
3. Iterates through OS folders (WINDOWS, MACOS, BYOD, WINDOWS365)
4. Processes each policy type subfolder
5. Creates policies with "Imported by Intune-Hydration-Kit" tag
6. Includes rate limiting (100ms delay) to avoid throttling

## Safety Features

- All imported policies are tagged in the description
- Only Hydration Kit-created policies can be deleted
- Existing policies are skipped, not overwritten
- Read-only Graph properties are automatically removed before import

## Related Functions

- [Get-OpenIntuneBaseline](Get-OpenIntuneBaseline.md)
- [Import-IntuneAppProtectionPolicy](Import-IntuneAppProtectionPolicy.md)
- [Import-IntuneCompliancePolicy](Import-IntuneCompliancePolicy.md)
