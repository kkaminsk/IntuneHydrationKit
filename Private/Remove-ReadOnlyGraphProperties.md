# Remove-ReadOnlyGraphProperties

## Synopsis

Removes read-only and system properties from a Graph API object before import.

## Description

Internal helper function that removes common read-only properties that cannot be included when creating or updating resources via Microsoft Graph API. This function modifies the input object in place and accepts additional properties to remove for resource-specific cleanup.

## Syntax

```powershell
Remove-ReadOnlyGraphProperties [-InputObject] <PSObject> [-AdditionalProperties <String[]>]
```

## Parameters

### -InputObject

The PSObject to remove properties from. **Note**: This object is modified in place.

| Attribute | Value |
|-----------|-------|
| Type | PSObject |
| Required | Yes |
| Position | 0 |
| Pipeline Input | No |

### -AdditionalProperties

Additional property names to remove beyond the core read-only set.

| Attribute | Value |
|-----------|-------|
| Type | String[] |
| Required | No |
| Position | Named |
| Default | @() (empty array) |

## Return Value

This function does not return a value. It modifies the `InputObject` in place.

## Core Read-Only Properties

The following properties are always removed:

| Property | Description |
|----------|-------------|
| `id` | The unique identifier assigned by Graph API |
| `createdDateTime` | Timestamp when the resource was created |
| `lastModifiedDateTime` | Timestamp of last modification |
| `version` | Resource version number |
| `@odata.context` | OData context URL |

## Examples

### Example 1: Basic usage with a policy object

```powershell
$policy = Get-Content "./Templates/Compliance/policy.json" | ConvertFrom-Json
Remove-ReadOnlyGraphProperties -InputObject $policy

# $policy no longer contains id, createdDateTime, etc.
$body = $policy | ConvertTo-Json -Depth 10
Invoke-MgGraphRequest -Uri "beta/deviceManagement/deviceCompliancePolicies" -Method POST -Body $body
```

### Example 2: Remove additional resource-specific properties

```powershell
$caPolicy = Get-Content "./Templates/ConditionalAccess/policy.json" | ConvertFrom-Json

# Conditional Access policies have additional read-only properties
Remove-ReadOnlyGraphProperties -InputObject $caPolicy -AdditionalProperties @(
    'createdDateTime',
    'modifiedDateTime',
    'templateId'
)
```

### Example 3: Use with Copy-DeepObject for safe modification

```powershell
# Get existing policy from Graph API
$existingPolicy = Invoke-MgGraphRequest -Uri "beta/deviceManagement/configurationPolicies/$policyId"

# Create a deep copy to avoid modifying cached data
$newPolicy = Copy-DeepObject -InputObject $existingPolicy

# Remove read-only properties for re-import
Remove-ReadOnlyGraphProperties -InputObject $newPolicy

# Now safe to POST as a new policy
```

### Example 4: Removing properties from App Protection policies

```powershell
$appPolicy = Get-Content "./Templates/AppProtection/ios-mam.json" | ConvertFrom-Json

Remove-ReadOnlyGraphProperties -InputObject $appPolicy -AdditionalProperties @(
    'deployedAppCount',
    'isAssigned'
)
```

## Common Additional Properties by Resource Type

| Resource Type | Additional Properties to Remove |
|--------------|--------------------------------|
| Conditional Access | `modifiedDateTime`, `templateId` |
| App Protection | `deployedAppCount`, `isAssigned` |
| Device Configuration | `supportsScopeTags` |
| Compliance Policy | `validOperatingSystemBuildRanges` |
| Assignment Filters | `payloads` |

## Notes

- This is a **private** function not exported by the module
- **Important**: The function modifies the input object directly; use `Copy-DeepObject` first if you need to preserve the original
- Properties that don't exist on the object are silently skipped
- This function should be called before any Graph API POST or PATCH operation

## Related Functions

- [Copy-DeepObject](Copy-DeepObject.md) - Create a copy before removing properties if original must be preserved
