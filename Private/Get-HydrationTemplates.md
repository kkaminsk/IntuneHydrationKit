# Get-HydrationTemplates

## Synopsis

Gets template files from a directory.

## Description

Internal helper function that retrieves JSON template files from a specified path. This function provides a consistent way to discover and load template files used throughout the Intune Hydration Kit for policies, groups, and other resources.

## Syntax

```powershell
Get-HydrationTemplates [-Path] <String> [-Recurse] [-ResourceType <String>]
```

## Parameters

### -Path

The directory path to search for template files.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes |
| Position | 0 |
| Pipeline Input | No |

### -Recurse

If specified, searches subdirectories recursively.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |
| Position | Named |
| Default | False |

### -ResourceType

The type of resource being loaded (for logging purposes).

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Position | Named |
| Default | "template" |

## Return Value

Returns an array of `FileInfo` objects representing the discovered JSON template files.

## Examples

### Example 1: Get all compliance policy templates

```powershell
$templates = Get-HydrationTemplates -Path "./Templates/Compliance"

foreach ($template in $templates) {
    $policy = Get-Content $template.FullName | ConvertFrom-Json
    Write-Host "Found template: $($policy.displayName)"
}
```

### Example 2: Recursively search for all templates

```powershell
$allTemplates = Get-HydrationTemplates -Path "./Templates" -Recurse -ResourceType "policy"
Write-Host "Found $($allTemplates.Count) policy templates"
```

### Example 3: Load and process conditional access templates

```powershell
$caTemplates = Get-HydrationTemplates -Path "./Templates/ConditionalAccess"

foreach ($templateFile in $caTemplates) {
    $caPolicy = Get-Content $templateFile.FullName -Raw | ConvertFrom-Json
    # Process each CA policy template
}
```

## Template Directory Structure

The Intune Hydration Kit uses the following template organization:

```
Templates/
├── AppProtection/       # App protection policy templates
├── Compliance/          # Device compliance policy templates
├── ConditionalAccess/   # Conditional access policy templates
├── DynamicGroups/       # Azure AD dynamic group templates
├── Enrollment/          # Device enrollment profile templates
└── Notifications/       # Notification template files
```

## Notes

- This is a **private** function not exported by the module
- Only returns files with `.json` extension
- Templates should follow Microsoft Graph API schema for the respective resource type
- The `-ResourceType` parameter is currently for informational purposes only

## Related Functions

- [New-HydrationResult](New-HydrationResult.md) - Used to track results of template processing
- [Remove-ReadOnlyGraphProperties](Remove-ReadOnlyGraphProperties.md) - Prepares loaded templates for Graph API submission
