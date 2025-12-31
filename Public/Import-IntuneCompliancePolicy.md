# Import-IntuneCompliancePolicy

## Synopsis

Imports device compliance policies from JSON templates.

## Description

Reads JSON templates from the Templates/Compliance directory and creates compliance policies in Microsoft Intune via the Graph API. Supports Windows, macOS, iOS, Android, and Linux compliance policies, including custom compliance policies with PowerShell detection scripts.

## Syntax

```powershell
Import-IntuneCompliancePolicy
    [-TemplatePath <String>]
    [-RemoveExisting]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -TemplatePath

Path to the compliance template directory containing JSON policy definitions.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `Templates/Compliance` |

### -RemoveExisting

When specified, removes existing compliance policies that were created by the Hydration Kit.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

## Outputs

**Array** - Returns an array of `HydrationResult` objects containing:
- `Name`: Policy display name
- `Type`: "CompliancePolicy"
- `Action`: Created, Skipped, Deleted, Failed, WouldCreate, or WouldDelete
- `Status`: Success, Already exists, DryRun, or error message
- `Path`: Template file path

## Graph API Endpoints

| Policy Type | Endpoint |
|-------------|----------|
| Windows/macOS/iOS/Android | `beta/deviceManagement/deviceCompliancePolicies` |
| Linux | `beta/deviceManagement/compliancePolicies` |

## Examples

### Example 1: Import all compliance policies

```powershell
Import-IntuneCompliancePolicy
```

Creates compliance policies from the default template directory.

### Example 2: Preview changes

```powershell
Import-IntuneCompliancePolicy -WhatIf
```

Shows what policies would be created without making changes.

### Example 3: Use custom templates

```powershell
Import-IntuneCompliancePolicy -TemplatePath "./MyPolicies/Compliance"
```

Creates policies from a custom template directory.

### Example 4: Remove Hydration Kit policies

```powershell
Import-IntuneCompliancePolicy -RemoveExisting
```

## Custom Compliance Policy Support

For custom compliance policies with PowerShell detection scripts, the template should include:

```json
{
  "displayName": "Custom Compliance Policy",
  "@odata.type": "#microsoft.graph.windows10CompliancePolicy",
  "deviceCompliancePolicyScript": {},
  "deviceCompliancePolicyScriptDefinition": {
    "displayName": "Detection Script Name",
    "detectionScriptContentBase64": "BASE64_ENCODED_SCRIPT",
    "rules": [
      {
        "settingName": "CustomSetting",
        "operator": "IsEquals",
        "dataType": "String",
        "operand": "ExpectedValue"
      }
    ]
  }
}
```

The function will:
1. Create or find the compliance detection script
2. Convert rules to base64 format
3. Link the script to the compliance policy

## Safety Features

- Pre-fetches existing policies to minimize API calls
- Only deletes policies with "Imported by Intune-Hydration-Kit" in description
- Existing policies are skipped, not overwritten
- Full `-WhatIf` support for dry-run previews

## Related Functions

- [Import-IntuneBaseline](Import-IntuneBaseline.md)
- [Import-IntuneAppProtectionPolicy](Import-IntuneAppProtectionPolicy.md)
