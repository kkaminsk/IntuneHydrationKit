# Write-HydrationLog

## Synopsis

Writes a log entry to both console and log file.

## Description

Writes formatted log messages with timestamp, level, and optional data to both the console (with color-coded output) and the session log file. This is the primary logging function used throughout the Intune Hydration Kit.

## Syntax

```powershell
Write-HydrationLog
    -Message <String>
    [-Level <String>]
    [-Data <Object>]
```

## Parameters

### -Message

The message to log.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | Yes |

### -Level

The severity level of the log message.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `Info` |
| Valid Values | `Info`, `Warning`, `Error`, `Debug` |

### -Data

Additional data to include in the log file (serialized as JSON).

| Attribute | Value |
|-----------|-------|
| Type | Object |
| Required | No |

## Console Output

Messages are displayed with level-specific icons and colors:

| Level | Icon | Color |
|-------|------|-------|
| Info | `[i]` | Cyan |
| Warning | `[!]` | Yellow |
| Error | `[x]` | Red |
| Debug | `[~]` | Gray |

### Special Formatting

- Messages starting with `Step N:` are displayed with a `▶` prefix and extra spacing
- Messages starting with `===` are displayed with extra spacing (section headers)
- Debug messages are suppressed unless verbose logging is enabled

## Examples

### Example 1: Basic info message

```powershell
Write-HydrationLog -Message "Starting policy import" -Level Info
```

Output: `  [i] Starting policy import`

### Example 2: Warning message

```powershell
Write-HydrationLog -Message "Policy already exists, skipping" -Level Warning
```

Output: `  [!] Policy already exists, skipping`

### Example 3: Error with data

```powershell
Write-HydrationLog -Message "API call failed" -Level Error -Data @{
    StatusCode = 403
    Endpoint = "beta/deviceManagement/configurationPolicies"
}
```

### Example 4: Step indicator

```powershell
Write-HydrationLog -Message "Step 1: Importing baseline policies" -Level Info
```

Output:
```

▶ Step 1: Importing baseline policies
```

### Example 5: Section header

```powershell
Write-HydrationLog -Message "=== Configuration Summary ===" -Level Info
```

## Log File Format

Entries are written to the log file in this format:
```
[2024-01-15 14:30:45] [Info] Starting policy import
[2024-01-15 14:30:46] [Warning] Policy already exists, skipping
```

When `-Data` is provided, JSON is appended:
```
[2024-01-15 14:30:47] [Error] API call failed
{
  "StatusCode": 403,
  "Endpoint": "beta/deviceManagement/configurationPolicies"
}
```

## Prerequisites

Requires `Initialize-HydrationLogging` to be called first to set up the log file.

## Script-Level Variables Used

| Variable | Purpose |
|----------|---------|
| `$script:CurrentLogFile` | Path to write log entries |
| `$script:VerboseLogging` | Whether to show Debug messages |

## Related Functions

- [Initialize-HydrationLogging](Initialize-HydrationLogging.md)
