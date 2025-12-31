# Get-ObfuscatedTenantId

## Synopsis

Obfuscates a tenant ID for safe logging.

## Description

Returns an obfuscated version of the tenant ID to prevent sensitive data exposure in logs. This function supports both GUID format tenant IDs and domain name formats, applying appropriate masking to each.

## Syntax

```powershell
Get-ObfuscatedTenantId [-TenantId] <String>
```

## Parameters

### -TenantId

The tenant ID to obfuscate. Can be either a GUID or domain name format.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes |
| Position | 0 |
| Pipeline Input | No |
| Validation | NotNullOrEmpty |

## Return Value

Returns a string with the obfuscated tenant ID:
- **GUID format**: Shows first 8 and last 12 characters with middle masked
- **Domain format**: Shows first 4 characters with rest masked

## Output Type

`[System.String]`

## Examples

### Example 1: Obfuscate a GUID tenant ID

```powershell
Get-ObfuscatedTenantId -TenantId "12345678-1234-1234-1234-123456789abc"
# Returns: 12345678****-****-****-123456789abc
```

### Example 2: Obfuscate a domain-based tenant ID

```powershell
Get-ObfuscatedTenantId -TenantId "contoso.onmicrosoft.com"
# Returns: cont***
```

### Example 3: Use in logging

```powershell
$tenantId = (Get-MgContext).TenantId
Write-Host "Connected to tenant: $(Get-ObfuscatedTenantId -TenantId $tenantId)"
# Output: Connected to tenant: 12345678****-****-****-123456789abc
```

### Example 4: Short domain name handling

```powershell
Get-ObfuscatedTenantId -TenantId "abc"
# Returns: abc***
```

## How It Works

The function uses regex to detect the tenant ID format:

1. **GUID Detection**: Pattern `^[a-f0-9-]{36}$` identifies standard Azure AD tenant GUIDs
2. **GUID Masking**: Preserves first 8 characters (before first hyphen) and last 12 characters (final segment)
3. **Domain Masking**: Shows only first 4 characters (or fewer if the domain is shorter) followed by `***`

## Security Considerations

- Prevents full tenant IDs from appearing in logs, console output, or error messages
- Maintains enough information for troubleshooting (partial ID visible)
- Should be used whenever tenant IDs are written to any output that may be shared

## Notes

- This is a **private** function not exported by the module
- The obfuscation is one-way; the original tenant ID cannot be recovered
- Used throughout the module for secure logging practices

## Related Functions

- [Initialize-HydrationLogging](../Public/Initialize-HydrationLogging.md) - Uses this function when logging connection details
