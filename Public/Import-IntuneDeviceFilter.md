# Import-IntuneDeviceFilter

## Synopsis

Creates device assignment filters for Intune.

## Description

Creates a predefined set of device assignment filters organized by manufacturer and device type for each platform (Windows, macOS, iOS/iPadOS, Android). These filters can be used to target or exclude specific devices when assigning policies and apps.

## Syntax

```powershell
Import-IntuneDeviceFilter
    [-RemoveExisting]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -RemoveExisting

When specified, removes existing device filters that were created by the Hydration Kit.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

## Outputs

**Array** - Returns an array of `HydrationResult` objects containing:
- `Name`: Filter display name
- `Id`: Filter ID (when created)
- `Platform`: Target platform
- `Action`: Created, Skipped, Deleted, Failed, WouldCreate, or WouldDelete
- `Status`: Success, Already exists, DryRun, or error message

## Predefined Filters

### Windows Filters

| Filter Name | Rule |
|-------------|------|
| Windows - Dell Devices | `(device.manufacturer -eq "Dell Inc.")` |
| Windows - HP Devices | `(device.manufacturer -eq "HP") or (device.manufacturer -eq "Hewlett-Packard")` |
| Windows - Lenovo Devices | `(device.manufacturer -eq "LENOVO")` |

### macOS Filters

| Filter Name | Rule |
|-------------|------|
| macOS - Apple Devices | `(device.manufacturer -eq "Apple")` |
| macOS - MacBook Devices | `(device.model -startsWith "MacBook")` |
| macOS - iMac Devices | `(device.model -startsWith "iMac")` |

### iOS/iPadOS Filters

| Filter Name | Rule |
|-------------|------|
| iOS - iPhone Devices | `(device.model -startsWith "iPhone")` |
| iOS - iPad Devices | `(device.model -startsWith "iPad")` |
| iOS - Corporate Owned | `(device.deviceOwnership -eq "Corporate")` |

### Android Filters

| Filter Name | Rule |
|-------------|------|
| Android - Samsung Devices | `(device.manufacturer -eq "samsung")` |
| Android - Google Pixel Devices | `(device.manufacturer -eq "Google")` |
| Android - Corporate Owned | `(device.deviceOwnership -eq "Corporate")` |

## Examples

### Example 1: Create all device filters

```powershell
Import-IntuneDeviceFilter
```

Creates all predefined device filters.

### Example 2: Preview changes

```powershell
Import-IntuneDeviceFilter -WhatIf
```

Shows what filters would be created without making changes.

### Example 3: Remove Hydration Kit filters

```powershell
Import-IntuneDeviceFilter -RemoveExisting
```

Removes all filters previously created by the Hydration Kit.

## Safety Features

- Only deletes filters with "Imported by Intune-Hydration-Kit" in the description
- Existing filters with the same name are skipped (not overwritten)
- Pre-fetches existing filters to minimize API calls
- Full `-WhatIf` support for dry-run previews

## Graph API Endpoint

| Operation | Endpoint |
|-----------|----------|
| List/Create/Delete | `beta/deviceManagement/assignmentFilters` |

## Related Functions

- [New-IntuneDynamicGroup](New-IntuneDynamicGroup.md)
- [Import-IntuneBaseline](Import-IntuneBaseline.md)
