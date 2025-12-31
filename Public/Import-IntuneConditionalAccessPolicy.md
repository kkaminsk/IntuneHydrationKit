# Import-IntuneConditionalAccessPolicy

## Synopsis

Imports Conditional Access policies from JSON templates.

## Description

Imports Conditional Access policies from templates with the state forced to **disabled** for safety. All policies are created in disabled state and must be manually enabled after review.

## Syntax

```powershell
Import-IntuneConditionalAccessPolicy
    [-TemplatePath <String>]
    [-Prefix <String>]
    [-RemoveExisting]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -TemplatePath

Path to the Conditional Access template directory containing JSON policy definitions.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `Templates/ConditionalAccess` |

### -Prefix

Optional prefix to add to all policy names for easy identification.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | Empty string |

### -RemoveExisting

When specified, removes existing Conditional Access policies that match template names AND are in disabled state.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

## Outputs

**Array** - Returns an array of `HydrationResult` objects containing:
- `Name`: Policy display name
- `Id`: Policy ID (when created or existing)
- `Action`: Created, Skipped, Deleted, Failed, WouldCreate, or WouldDelete
- `Status`: Success, Already exists, DryRun, or error message
- `State`: Policy state (always "disabled" for new policies)

## Examples

### Example 1: Import CA policies

```powershell
Import-IntuneConditionalAccessPolicy
```

Creates Conditional Access policies in disabled state from the default template directory.

### Example 2: Import with prefix

```powershell
Import-IntuneConditionalAccessPolicy -Prefix "Hydration - "
```

Creates policies with names like "Hydration - Block Legacy Auth".

### Example 3: Preview changes

```powershell
Import-IntuneConditionalAccessPolicy -WhatIf
```

Shows what policies would be created without making changes.

### Example 4: Remove disabled policies

```powershell
Import-IntuneConditionalAccessPolicy -RemoveExisting -Prefix "Hydration - "
```

Removes only disabled policies that match template names with the specified prefix.

## Safety Features

- **All policies created in disabled state** - Policies must be manually enabled after review
- **Delete protection** - Only deletes policies that:
  1. Match a template name (with prefix if specified)
  2. Are currently in disabled state
- Enabled or report-only policies are never deleted
- Full `-WhatIf` support for dry-run previews

## Template Structure

Templates should follow the Microsoft Graph Conditional Access policy schema:

```json
{
  "displayName": "Block Legacy Authentication",
  "conditions": {
    "applications": {
      "includeApplications": ["All"]
    },
    "clientAppTypes": ["exchangeActiveSync", "other"]
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["block"]
  }
}
```

Note: The `state` property in templates is ignored - policies are always created as disabled.

## Graph API Endpoint

| Operation | Endpoint |
|-----------|----------|
| List/Create/Delete | `beta/identity/conditionalAccess/policies` |

## Related Functions

- [Test-IntunePrerequisites](Test-IntunePrerequisites.md)
- [Connect-IntuneHydration](Connect-IntuneHydration.md)
