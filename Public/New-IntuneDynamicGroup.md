# New-IntuneDynamicGroup

## Synopsis

Creates a dynamic Azure AD group for use with Intune.

## Description

Creates a dynamic membership group in Azure AD/Entra ID with the specified membership rule. Dynamic groups automatically include or exclude members based on user or device attributes. If a group with the same name already exists, the existing group is returned without modification.

## Syntax

```powershell
New-IntuneDynamicGroup
    -DisplayName <String>
    [-Description <String>]
    -MembershipRule <String>
    [-MembershipRuleProcessingState <String>]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -DisplayName

The display name for the group. Must be unique within the tenant.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes |

### -Description

Description of the group's purpose.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | Empty string |

### -MembershipRule

The OData membership rule that defines dynamic membership. Must start with a parenthesis.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes |
| Validation | Must start with `(` |

### -MembershipRuleProcessingState

Controls whether the membership rule is actively processed.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `On` |
| Valid Values | `On`, `Paused` |

## Outputs

**HydrationResult** - Returns a result object containing:
- `Name`: Group display name
- `Id`: Group ID (when created or existing)
- `Type`: "DynamicGroup"
- `Action`: Created, Skipped, WouldCreate, or Failed
- `Status`: Description of the outcome

## Examples

### Example 1: Create a Windows 11 devices group

```powershell
New-IntuneDynamicGroup -DisplayName "Windows 11 Devices" `
    -MembershipRule "(device.operatingSystem -eq 'Windows') and (device.operatingSystemVersion -startsWith '10.0.22')"
```

### Example 2: Create a group for corporate devices

```powershell
New-IntuneDynamicGroup -DisplayName "Corporate Owned Devices" `
    -Description "All corporate-owned devices" `
    -MembershipRule "(device.deviceOwnership -eq 'Corporate')"
```

### Example 3: Create a user group by department

```powershell
New-IntuneDynamicGroup -DisplayName "IT Department Users" `
    -MembershipRule "(user.department -eq 'IT')"
```

### Example 4: Preview group creation

```powershell
New-IntuneDynamicGroup -DisplayName "Test Group" `
    -MembershipRule "(device.manufacturer -eq 'Dell')" `
    -WhatIf
```

## Common Membership Rules

### Device-based Rules

| Purpose | Rule |
|---------|------|
| Windows devices | `(device.deviceOSType -eq "Windows")` |
| macOS devices | `(device.deviceOSType -eq "MacMDM")` |
| iOS devices | `(device.deviceOSType -eq "iPhone") or (device.deviceOSType -eq "iPad")` |
| Android devices | `(device.deviceOSType -eq "Android")` |
| Corporate devices | `(device.deviceOwnership -eq "Corporate")` |
| Personal (BYOD) | `(device.deviceOwnership -eq "Personal")` |

### User-based Rules

| Purpose | Rule |
|---------|------|
| By department | `(user.department -eq "Finance")` |
| By job title | `(user.jobTitle -contains "Manager")` |
| By country | `(user.country -eq "United States")` |

## Safety Features

- Groups are tagged with "Imported by Intune-Hydration-Kit" in description
- Existing groups with the same name are not modified
- Full `-WhatIf` support for dry-run previews
- Pagination support for checking existing groups

## Graph API Endpoint

| Operation | Endpoint |
|-----------|----------|
| List/Create | `beta/groups` |

## Related Functions

- [Import-IntuneDeviceFilter](Import-IntuneDeviceFilter.md)
- [Connect-IntuneHydration](Connect-IntuneHydration.md)
