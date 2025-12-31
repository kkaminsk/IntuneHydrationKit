# Get-GraphErrorMessage

## Synopsis

Extracts error message from Graph API error response.

## Description

Internal helper function for parsing Graph API error details from PowerShell error records. This function provides a consistent way to extract meaningful error messages from Microsoft Graph API failures, which can contain error details in different locations within the error record.

## Syntax

```powershell
Get-GraphErrorMessage [-ErrorRecord] <ErrorRecord>
```

## Parameters

### -ErrorRecord

The PowerShell error record to extract the message from.

| Attribute | Value |
|-----------|-------|
| Type | System.Management.Automation.ErrorRecord |
| Required | Yes |
| Position | 0 |
| Pipeline Input | No |

## Return Value

Returns a string containing the error message. Prioritizes `ErrorDetails.Message` (which typically contains the Graph API response) over `Exception.Message`.

## Examples

### Example 1: Extract error message in a try/catch block

```powershell
try {
    Invoke-MgGraphRequest -Uri "beta/deviceManagement/configurationPolicies" -Method POST -Body $body
}
catch {
    $errorMessage = Get-GraphErrorMessage -ErrorRecord $_
    Write-Error "Failed to create policy: $errorMessage"
}
```

### Example 2: Use with New-HydrationResult for failure tracking

```powershell
try {
    # Graph API call
}
catch {
    $errorMessage = Get-GraphErrorMessage -ErrorRecord $_
    New-HydrationResult -Name $policyName -Action "Failed" -Status $errorMessage
}
```

## How It Works

The function checks two locations for error information:

1. **ErrorDetails.Message** - Checked first; contains the actual HTTP response body from Graph API failures, typically including detailed error codes and messages
2. **Exception.Message** - Fallback; contains the PowerShell exception message if ErrorDetails is not populated

## Graph API Error Format

When Graph API returns an error, the `ErrorDetails.Message` typically contains JSON like:

```json
{
    "error": {
        "code": "BadRequest",
        "message": "The property 'invalidProperty' does not exist.",
        "innerError": {
            "date": "2024-01-15T10:30:00",
            "request-id": "abc123"
        }
    }
}
```

## Notes

- This is a **private** function not exported by the module
- Always use this function in catch blocks when working with Graph API calls for consistent error handling
- The returned message may be JSON; consider parsing if you need specific error details

## Related Functions

- [New-HydrationResult](New-HydrationResult.md) - Uses this function's output for the Status field on failures
