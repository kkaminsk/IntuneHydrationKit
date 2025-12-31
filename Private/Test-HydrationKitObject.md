# Test-HydrationKitObject

## Synopsis

Tests if an object was created by the Intune-Hydration-Kit.

## Description

Checks if an object's description contains "Imported by Intune-Hydration-Kit". This is the standard marker used to identify objects created by this module, enabling safe cleanup operations that only affect kit-created resources.

## Syntax

```powershell
Test-HydrationKitObject [[-Description] <String>] [-ObjectName <String>]
```

## Parameters

### -Description

The description field of the object to check.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | 0 |
| Pipeline Input | No |
| Validation | AllowNull, AllowEmptyString |

### -ObjectName

Optional. The name of the object for logging purposes.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

## Return Value

Returns `$true` if the object was created by Intune-Hydration-Kit, `$false` otherwise.

## Output Type

`[System.Boolean]`

## Examples

### Example 1: Check before deletion

```powershell
$policy = Invoke-MgGraphRequest -Uri "beta/deviceManagement/deviceCompliancePolicies/$policyId"

if (Test-HydrationKitObject -Description $policy.description) {
    # Safe to delete - this was created by the kit
    Invoke-MgGraphRequest -Uri "beta/deviceManagement/deviceCompliancePolicies/$policyId" -Method DELETE
}
else {
    Write-Warning "Policy was not created by Hydration Kit - skipping deletion"
}
```

### Example 2: Filter objects for cleanup

```powershell
$allPolicies = Invoke-MgGraphRequest -Uri "beta/deviceManagement/deviceCompliancePolicies"

$kitPolicies = $allPolicies.value | Where-Object {
    Test-HydrationKitObject -Description $_.description -ObjectName $_.displayName
}

Write-Host "Found $($kitPolicies.Count) policies created by Hydration Kit"
```

### Example 3: Verbose logging

```powershell
$VerbosePreference = "Continue"

Test-HydrationKitObject -Description "My Policy - Imported by Intune-Hydration-Kit" -ObjectName "My Policy"
# VERBOSE: Object 'My Policy' is a Hydration Kit object (marker found in description)
# Returns: True

Test-HydrationKitObject -Description "Manually created policy" -ObjectName "Manual Policy"
# VERBOSE: Object 'Manual Policy' is NOT a Hydration Kit object (no marker in description)
# Returns: False
```

### Example 4: Handle null descriptions

```powershell
$policy = @{ displayName = "Test"; description = $null }

$isKitObject = Test-HydrationKitObject -Description $policy.description -ObjectName $policy.displayName
# VERBOSE: Object 'Test' has no description - not a Hydration Kit object
# Returns: False
```

## Marker Strings

The function checks for two variations of the marker:

| Marker | Format |
|--------|--------|
| Primary | `Imported by Intune-Hydration-Kit` |
| Alternate | `Imported by Intune Hydration Kit` |

Both markers are checked using wildcard matching (`-like "*marker*"`), so they can appear anywhere in the description.

## Safety Pattern

This function is a critical safety mechanism in the Intune Hydration Kit:

1. **Creation**: All objects created by the kit include the marker in their description
2. **Identification**: This function identifies kit-created objects
3. **Protection**: Cleanup/deletion operations only affect objects that pass this test
4. **Preservation**: Manually created or third-party objects are never modified or deleted

```
┌─────────────────────────────────────────────────────────┐
│                    Object in Tenant                      │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
              ┌────────────────────────┐
              │ Test-HydrationKitObject │
              └────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │                         │
              ▼                         ▼
     ┌────────────────┐       ┌────────────────┐
     │  Returns True  │       │  Returns False │
     │  (Kit Object)  │       │ (External Obj) │
     └────────────────┘       └────────────────┘
              │                         │
              ▼                         ▼
     ┌────────────────┐       ┌────────────────┐
     │ Safe to modify │       │   Protected    │
     │   or delete    │       │  from changes  │
     └────────────────┘       └────────────────┘
```

## Notes

- This is a **private** function not exported by the module
- Always use this function before performing destructive operations
- Null or empty descriptions return `$false`
- The `-ObjectName` parameter only affects verbose logging, not the return value

## Related Functions

- [New-HydrationResult](New-HydrationResult.md) - Creates result objects for operations that use this check
