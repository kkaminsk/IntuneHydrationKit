# Get-OpenIntuneBaseline

## Synopsis

Downloads OpenIntuneBaseline repository from GitHub.

## Description

Downloads and extracts the OpenIntuneBaseline repository containing community security baseline policies for Microsoft Intune. The repository is downloaded as a ZIP archive and extracted to the specified destination path.

## Syntax

```powershell
Get-OpenIntuneBaseline
    [-RepoUrl <String>]
    [-Branch <String>]
    [-DestinationPath <String>]
```

## Parameters

### -RepoUrl

GitHub repository URL for the OpenIntuneBaseline project.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `https://github.com/SkipToTheEndpoint/OpenIntuneBaseline` |

### -Branch

Branch to download from the repository.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `main` |

### -DestinationPath

Path to extract the repository contents. If not specified, uses the system temp directory.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `<TempPath>/OpenIntuneBaseline` |

## Outputs

**String** - Returns the path to the extracted baseline directory.

## Examples

### Example 1: Download to default location

```powershell
Get-OpenIntuneBaseline
```

Downloads OpenIntuneBaseline to the system temp directory.

### Example 2: Download to custom location

```powershell
Get-OpenIntuneBaseline -DestinationPath ./Baselines
```

Downloads and extracts the baselines to a local `Baselines` folder.

### Example 3: Download a specific branch

```powershell
Get-OpenIntuneBaseline -Branch "develop" -DestinationPath "C:\Baselines"
```

Downloads the `develop` branch to a specific directory.

## Notes

- The function automatically cleans up existing directories before extraction
- ZIP files are deleted after successful extraction
- The extracted folder structure is flattened to remove the GitHub archive subfolder
- This function is typically called automatically by `Import-IntuneBaseline` if no baseline path is provided

## Related Functions

- [Import-IntuneBaseline](Import-IntuneBaseline.md)
