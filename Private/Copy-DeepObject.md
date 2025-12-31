# Copy-DeepObject

## Synopsis

Creates a deep copy of a PowerShell object.

## Description

Internal helper function that creates a complete deep clone of an object using PowerShell serialization. This ensures nested objects and collections are fully copied rather than referenced.

This function is essential when you need to modify a copy of an object without affecting the original, particularly when working with complex nested structures like Graph API responses.

## Syntax

```powershell
Copy-DeepObject [-InputObject] <Object>
```

## Parameters

### -InputObject

The object to deep copy.

| Attribute | Value |
|-----------|-------|
| Type | Object |
| Required | Yes |
| Position | 0 |
| Pipeline Input | No |

## Return Value

Returns a complete deep clone of the input object with no shared references to the original.

## Examples

### Example 1: Deep copy a policy object

```powershell
$originalPolicy = @{
    Name = "Test Policy"
    Settings = @{
        Enabled = $true
        Options = @("Option1", "Option2")
    }
}

$copiedPolicy = Copy-DeepObject -InputObject $originalPolicy

# Modifying the copy does not affect the original
$copiedPolicy.Settings.Enabled = $false
$originalPolicy.Settings.Enabled  # Still $true
```

### Example 2: Clone a Graph API response before modification

```powershell
$graphResponse = Invoke-MgGraphRequest -Uri "beta/deviceManagement/configurationPolicies"
$workingCopy = Copy-DeepObject -InputObject $graphResponse

# Safe to modify $workingCopy without affecting cached data
```

## How It Works

The function uses PowerShell's built-in serialization mechanism:

1. `PSSerializer::Serialize()` converts the object to CLIXML format
2. `PSSerializer::Deserialize()` reconstructs a new object from the serialized data

This approach handles:
- Nested hashtables and arrays
- PSCustomObjects
- Complex object graphs
- Circular references (within serialization limits)

## Notes

- This is a **private** function not exported by the module
- Performance consideration: Serialization has overhead for very large objects
- Some object types may not serialize correctly (e.g., live connections, file handles)

## Related Functions

- [Remove-ReadOnlyGraphProperties](Remove-ReadOnlyGraphProperties.md) - Often used after copying to prepare objects for Graph API calls
