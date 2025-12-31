# Import-IntuneEnrollmentProfile

## Synopsis

Imports Windows enrollment profiles including Autopilot and Enrollment Status Page.

## Description

Creates Windows Autopilot deployment profiles and Enrollment Status Page (ESP) configurations from JSON templates. These profiles control the out-of-box experience (OOBE) and device setup process for Windows devices.

## Syntax

```powershell
Import-IntuneEnrollmentProfile
    [-TemplatePath <String>]
    [-DeviceNameTemplate <String>]
    [-RemoveExisting]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -TemplatePath

Path to the enrollment template directory containing JSON profile definitions.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `Templates/Enrollment` |

### -DeviceNameTemplate

Custom device naming template for Autopilot profiles. Overrides the template's `deviceNameTemplate` value.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | Uses template value (typically `%SERIAL%`) |

### -RemoveExisting

When specified, removes existing enrollment profiles that were created by the Hydration Kit.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

## Outputs

**Array** - Returns an array of `HydrationResult` objects containing:
- `Name`: Profile display name
- `Id`: Profile ID (when created)
- `Type`: "AutopilotDeploymentProfile" or "EnrollmentStatusPage"
- `Action`: Created, Skipped, Deleted, Failed, WouldCreate, or WouldDelete
- `Status`: Success, Already exists, DryRun, or error message

## Expected Template Files

The function looks for specific template files in the template directory:

| File | Description |
|------|-------------|
| `Windows-Autopilot-Profile.json` | Autopilot deployment profile settings |
| `Windows-ESP-Profile.json` | Enrollment Status Page configuration |

## Examples

### Example 1: Import enrollment profiles

```powershell
Import-IntuneEnrollmentProfile
```

Creates Autopilot and ESP profiles from the default template directory.

### Example 2: Custom device naming

```powershell
Import-IntuneEnrollmentProfile -DeviceNameTemplate "CORP-%SERIAL%"
```

Creates profiles with custom device naming template.

### Example 3: Preview changes

```powershell
Import-IntuneEnrollmentProfile -WhatIf
```

Shows what profiles would be created without making changes.

### Example 4: Remove Hydration Kit profiles

```powershell
Import-IntuneEnrollmentProfile -RemoveExisting
```

Removes Autopilot and ESP profiles created by the Hydration Kit.

## Template Examples

### Autopilot Profile Template

```json
{
  "@odata.type": "#microsoft.graph.azureADWindowsAutopilotDeploymentProfile",
  "displayName": "Windows Autopilot Profile",
  "description": "Standard Windows deployment profile",
  "deviceNameTemplate": "%SERIAL%",
  "deviceType": "windowsPc",
  "enableWhiteGlove": true,
  "outOfBoxExperienceSettings": {
    "hidePrivacySettings": true,
    "hideEULA": true,
    "userType": "standard",
    "deviceUsageType": "singleUser"
  }
}
```

### ESP Profile Template

```json
{
  "displayName": "Enrollment Status Page",
  "description": "Standard ESP configuration",
  "showInstallationProgress": true,
  "blockDeviceSetupRetryByUser": false,
  "allowDeviceResetOnInstallFailure": true,
  "allowLogCollectionOnInstallFailure": true,
  "installProgressTimeoutInMinutes": 60,
  "allowDeviceUseOnInstallFailure": true
}
```

## Graph API Endpoints

| Resource | Endpoint |
|----------|----------|
| Autopilot Profiles | `beta/deviceManagement/windowsAutopilotDeploymentProfiles` |
| ESP Profiles | `beta/deviceManagement/deviceEnrollmentConfigurations` |

## Safety Features

- Only deletes profiles with "Imported by Intune-Hydration-Kit" in description
- Existing profiles with the same name are skipped
- Full `-WhatIf` support for dry-run previews

## Related Functions

- [Import-IntuneBaseline](Import-IntuneBaseline.md)
- [New-IntuneDynamicGroup](New-IntuneDynamicGroup.md)
