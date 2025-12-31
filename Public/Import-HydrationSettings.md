# Import-HydrationSettings

## Synopsis

Imports and validates hydration settings from a JSON configuration file.

## Description

Reads a settings JSON file and validates that all required fields are present. The settings file contains tenant configuration and feature flags that control the hydration process.

## Syntax

```powershell
Import-HydrationSettings
    -Path <String>
```

## Parameters

### -Path

Path to the settings JSON file. The file must exist and be valid JSON.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes |
| Position | Named |
| Validation | File must exist (Test-Path) |

## Outputs

**Hashtable** - Returns the parsed settings as a hashtable with all configuration values.

## Examples

### Example 1: Load settings file

```powershell
$settings = Import-HydrationSettings -Path "./settings.json"
```

Loads and validates the settings from the specified JSON file.

### Example 2: Use in hydration workflow

```powershell
$config = Import-HydrationSettings -Path "./my-tenant-settings.json"
Write-Host "Configuring tenant: $($config.tenant.tenantId)"
```

## Settings File Structure

The settings file must contain at minimum:

```json
{
  "tenant": {
    "tenantId": "your-tenant-id-here"
  }
}
```

See `settings.example.json` for a complete example with all available options.

## Required Fields

| Field | Description |
|-------|-------------|
| `tenant.tenantId` | The Azure AD tenant ID (GUID or domain) |

## Error Handling

- Throws an error if the file cannot be read or parsed
- Throws an error if required fields are missing
- Logs errors via `Write-HydrationLog`

## Related Functions

- [Initialize-HydrationLogging](Initialize-HydrationLogging.md)
- [Connect-IntuneHydration](Connect-IntuneHydration.md)
