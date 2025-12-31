# Get-ResultSummary

## Synopsis

Calculates summary statistics from hydration results.

## Description

Internal helper function for aggregating result counts by action type. This function takes an array of hydration results and produces a summary hashtable showing counts for each action category.

## Syntax

```powershell
Get-ResultSummary [[-Results] <Array>]
```

## Parameters

### -Results

An array of result objects from hydration operations. Each result should have an `Action` property.

| Attribute | Value |
|-----------|-------|
| Type | Array |
| Required | No |
| Position | 0 |
| Pipeline Input | No |
| Default | @() (empty array) |

## Return Value

Returns a hashtable with counts for each action type:

| Key | Description |
|-----|-------------|
| Created | Resources successfully created |
| Updated | Resources successfully updated |
| Deleted | Resources successfully deleted |
| Skipped | Resources skipped (already exist, etc.) |
| WouldCreate | Resources that would be created (WhatIf mode) |
| WouldUpdate | Resources that would be updated (WhatIf mode) |
| WouldDelete | Resources that would be deleted (WhatIf mode) |
| Failed | Operations that failed |

## Examples

### Example 1: Get summary after policy import

```powershell
$results = @()
$results += New-HydrationResult -Name "Policy1" -Action "Created" -Status "Success"
$results += New-HydrationResult -Name "Policy2" -Action "Skipped" -Status "Already exists"
$results += New-HydrationResult -Name "Policy3" -Action "Created" -Status "Success"
$results += New-HydrationResult -Name "Policy4" -Action "Failed" -Status "Permission denied"

$summary = Get-ResultSummary -Results $results

# $summary:
# @{
#     Created = 2
#     Updated = 0
#     Deleted = 0
#     Skipped = 1
#     WouldCreate = 0
#     WouldUpdate = 0
#     WouldDelete = 0
#     Failed = 1
# }
```

### Example 2: Display summary to user

```powershell
$summary = Get-ResultSummary -Results $allResults

Write-Host "`nHydration Summary:"
Write-Host "  Created: $($summary.Created)"
Write-Host "  Skipped: $($summary.Skipped)"
Write-Host "  Failed:  $($summary.Failed)"
```

### Example 3: WhatIf mode summary

```powershell
# After running with -WhatIf
$summary = Get-ResultSummary -Results $dryRunResults

if ($summary.WouldCreate -gt 0) {
    Write-Host "$($summary.WouldCreate) resources would be created"
}
if ($summary.WouldDelete -gt 0) {
    Write-Warning "$($summary.WouldDelete) resources would be deleted"
}
```

### Example 4: Check for failures

```powershell
$summary = Get-ResultSummary -Results $results

if ($summary.Failed -gt 0) {
    Write-Error "Hydration completed with $($summary.Failed) failures"
    exit 1
}
```

## How It Works

The function performs a single-pass iteration through the results array for optimal performance:

1. Initializes a hashtable with all action types set to 0
2. Iterates through each result object
3. Increments the counter for matching action types
4. Returns the completed summary hashtable

## Notes

- This is a **private** function not exported by the module
- Results with unrecognized Action values are ignored
- Empty or null Results parameter returns all zeros
- Used by the main orchestrator script to display final status

## Related Functions

- [New-HydrationResult](New-HydrationResult.md) - Creates the result objects consumed by this function
