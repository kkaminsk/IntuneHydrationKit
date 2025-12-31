# Import-IntuneAppProtectionPolicy

## Synopsis

Imports app protection (MAM) policies from JSON templates.

## Description

Reads app protection policy templates and creates Android and iOS managed app protection policies in Microsoft Intune via the Graph API. Supports both creating new policies and removing existing ones created by the Hydration Kit.

## Syntax

```powershell
Import-IntuneAppProtectionPolicy
    [-TemplatePath <String>]
    [-RemoveExisting]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -TemplatePath

Path to the app protection template directory containing JSON policy definitions.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `Templates/AppProtection` |

### -RemoveExisting

When specified, removes existing app protection policies that were created by the Hydration Kit (identified by "Imported by Intune-Hydration-Kit" in the description).

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

### -WhatIf

Shows what would happen if the command runs without actually making changes.

### -Confirm

Prompts for confirmation before each policy creation or deletion.

## Outputs

**Array** - Returns an array of `HydrationResult` objects containing:
- `Name`: Policy display name
- `Type`: "AppProtection"
- `Action`: Created, Skipped, Deleted, Failed, WouldCreate, or WouldDelete
- `Status`: Success, Already exists, DryRun, or error message
- `Path`: Template file path (when applicable)

## Supported Policy Types

| @odata.type | Description |
|-------------|-------------|
| `#microsoft.graph.androidManagedAppProtection` | Android app protection policy |
| `#microsoft.graph.iosManagedAppProtection` | iOS/iPadOS app protection policy |

## Examples

### Example 1: Import all app protection policies

```powershell
Import-IntuneAppProtectionPolicy
```

Creates app protection policies from the default template directory.

### Example 2: Preview changes

```powershell
Import-IntuneAppProtectionPolicy -WhatIf
```

Shows what policies would be created without making changes.

### Example 3: Remove Hydration Kit policies

```powershell
Import-IntuneAppProtectionPolicy -RemoveExisting
```

Removes all app protection policies that were previously created by the Hydration Kit.

### Example 4: Use custom templates

```powershell
Import-IntuneAppProtectionPolicy -TemplatePath "./CustomPolicies/MAM"
```

Creates policies from a custom template directory.

## Safety Features

- Only deletes policies with "Imported by Intune-Hydration-Kit" in the description
- Existing policies with the same name are skipped (not overwritten)
- Full `-WhatIf` support for dry-run previews

## Graph API Endpoints

| Operation | Endpoint |
|-----------|----------|
| List/Create Android | `beta/deviceAppManagement/androidManagedAppProtections` |
| List/Create iOS | `beta/deviceAppManagement/iosManagedAppProtections` |

## Related Functions

- [Import-IntuneBaseline](Import-IntuneBaseline.md)
- [Import-IntuneCompliancePolicy](Import-IntuneCompliancePolicy.md)
