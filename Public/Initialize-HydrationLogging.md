# Initialize-HydrationLogging

## Synopsis

Initializes logging for the hydration session.

## Description

Sets up the logging infrastructure for the Intune Hydration Kit, creating log directories and initializing the log file with a timestamp. All subsequent `Write-HydrationLog` calls will write to this log file.

## Syntax

```powershell
Initialize-HydrationLogging
    [-LogPath <String>]
    [-EnableVerbose]
```

## Parameters

### -LogPath

Path to the directory where log files will be created.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `./Logs` |

### -EnableVerbose

Enables verbose logging, which includes Debug-level messages in the console output.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

## Log File Format

Log files are created with a timestamp-based name:
```
hydration-YYYYMMDD-HHmmss.log
```

Each log entry follows this format:
```
[2024-01-15 14:30:45] [Info] Message text here
```

## Examples

### Example 1: Initialize with defaults

```powershell
Initialize-HydrationLogging
```

Creates logs in the `./Logs` directory with standard verbosity.

### Example 2: Custom log path with verbose

```powershell
Initialize-HydrationLogging -LogPath "C:\IntuneHydration\Logs" -EnableVerbose
```

Creates logs in a custom directory with verbose output enabled.

### Example 3: Use in automation script

```powershell
# Start of hydration script
Initialize-HydrationLogging -LogPath "./Logs"
Write-HydrationLog -Message "Starting hydration process" -Level Info

# ... hydration operations ...

Write-HydrationLog -Message "Hydration complete" -Level Info
```

## Script-Level Variables

The function sets the following script-scoped variables:

| Variable | Description |
|----------|-------------|
| `$script:LogPath` | Path to the log directory |
| `$script:VerboseLogging` | Whether verbose logging is enabled |
| `$script:CurrentLogFile` | Full path to the current log file |

## Notes

- The log directory is created if it doesn't exist
- Existing log files are not overwritten; each session gets a new file
- The function clears any existing content if a log file with the same name exists

## Related Functions

- [Write-HydrationLog](Write-HydrationLog.md)
