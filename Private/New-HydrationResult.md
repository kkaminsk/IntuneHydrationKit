# New-HydrationResult

## Synopsis

Creates a standardized result object for hydration operations.

## Description

Internal helper function for creating consistent result objects across all hydration operations. This function ensures uniform tracking and reporting of all actions performed by the Intune Hydration Kit.

## Syntax

```powershell
New-HydrationResult [-Name <String>] [-Path <String>] [-Type <String>] [-Action <String>]
                    [-Status <String>] [-Id <String>] [-Platform <String>] [-State <String>]
```

## Parameters

### -Name

The display name of the resource.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

### -Path

The file path of the template used (if applicable).

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

### -Type

The type of resource (e.g., "CompliancePolicy", "ConditionalAccess").

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

### -Action

The action performed. Standard values:
- `Created` - Resource was created
- `Updated` - Resource was updated
- `Deleted` - Resource was deleted
- `Skipped` - Resource was skipped
- `WouldCreate` - Would create (WhatIf)
- `WouldUpdate` - Would update (WhatIf)
- `WouldDelete` - Would delete (WhatIf)
- `Failed` - Operation failed

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

### -Status

Status message or details. Alias: `Details`.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |
| Aliases | Details |

### -Id

The Graph API ID of the created/modified resource.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

### -Platform

The platform the resource targets (e.g., "Windows", "iOS", "Android").

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

### -State

The state of the resource (e.g., "enabled", "disabled").

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |

## Return Value

Returns a `PSCustomObject` with the following base properties:
- `Name` - Resource name
- `Action` - Action performed
- `Status` - Status/details message
- `Timestamp` - When the result was created (yyyy-MM-dd HH:mm:ss)

Additional properties (Path, Type, Id, Platform, State) are added only when provided.

## Examples

### Example 1: Record a successful creation

```powershell
$result = New-HydrationResult -Name "Windows Compliance Policy" `
    -Type "CompliancePolicy" `
    -Action "Created" `
    -Status "Success" `
    -Id "abc123-def456" `
    -Platform "Windows"
```

### Example 2: Record a skipped resource

```powershell
$result = New-HydrationResult -Name "Existing Policy" `
    -Action "Skipped" `
    -Status "Already exists"
```

### Example 3: Record a failure with error details

```powershell
try {
    # Graph API call
}
catch {
    $errorMessage = Get-GraphErrorMessage -ErrorRecord $_
    $result = New-HydrationResult -Name $policyName `
        -Type "ConfigurationPolicy" `
        -Action "Failed" `
        -Status $errorMessage `
        -Path $templateFile.FullName
}
```

### Example 4: WhatIf mode result

```powershell
if ($WhatIfPreference) {
    $result = New-HydrationResult -Name $policy.displayName `
        -Action "WouldCreate" `
        -Status "DryRun" `
        -Type "ConditionalAccess" `
        -State "disabled"
}
```

### Example 5: Collect results for summary

```powershell
$results = @()

foreach ($template in $templates) {
    # Process template...
    $results += New-HydrationResult -Name $template.Name -Action "Created" -Status "Success"
}

# Get summary
$summary = Get-ResultSummary -Results $results
```

## Output Format

Example output object:

```powershell
Name      : Windows Compliance Policy
Action    : Created
Status    : Success
Timestamp : 2024-01-15 14:30:45
Type      : CompliancePolicy
Id        : abc123-def456
Platform  : Windows
```

## Notes

- This is a **private** function not exported by the module
- All public import functions should use this to report results
- The `Status` parameter has an alias `Details` for flexibility
- Optional properties are only added when values are provided (no null properties)

## Related Functions

- [Get-ResultSummary](Get-ResultSummary.md) - Aggregates results created by this function
- [Get-GraphErrorMessage](Get-GraphErrorMessage.md) - Extracts error messages for the Status field
