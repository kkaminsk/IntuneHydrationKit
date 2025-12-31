# Import-IntuneNotificationTemplate

## Synopsis

Imports notification message templates from JSON templates.

## Description

Creates notification message templates in Microsoft Intune that can be used with compliance policy actions to notify users about non-compliant devices. Supports localized messages for multiple languages.

## Syntax

```powershell
Import-IntuneNotificationTemplate
    [-TemplatePath <String>]
    [-RemoveExisting]
    [-WhatIf]
    [-Confirm]
```

## Parameters

### -TemplatePath

Path to the notifications template directory containing JSON definitions.

| Attribute | Value |
|-----------|-------|
| Type | String |
| Required | No |
| Default | `Templates/Notifications` |

### -RemoveExisting

When specified, removes existing notification templates that were created by the Hydration Kit.

| Attribute | Value |
|-----------|-------|
| Type | Switch |
| Required | No |

## Outputs

**Array** - Returns an array of `HydrationResult` objects containing:
- `Name`: Template display name
- `Type`: "NotificationTemplate"
- `Action`: Created, Skipped, Deleted, Failed, WouldCreate, or WouldDelete
- `Status`: Success, Already exists, DryRun, or error message
- `Path`: Template file path

## Examples

### Example 1: Import notification templates

```powershell
Import-IntuneNotificationTemplate
```

Creates notification templates from the default template directory.

### Example 2: Preview changes

```powershell
Import-IntuneNotificationTemplate -WhatIf
```

Shows what templates would be created without making changes.

### Example 3: Use custom templates

```powershell
Import-IntuneNotificationTemplate -TemplatePath "./MyTemplates/Notifications"
```

Creates templates from a custom directory.

### Example 4: Remove Hydration Kit templates

```powershell
Import-IntuneNotificationTemplate -RemoveExisting
```

## Template Structure

Templates should include the main notification and optional localized messages:

```json
{
  "displayName": "Compliance Notification",
  "brandingOptions": "includeCompanyLogo,includeCompanyName",
  "defaultLocale": "en-us",
  "localizedMessages": [
    {
      "locale": "en-us",
      "subject": "Your device is not compliant",
      "messageTemplate": "Please take action to make your device compliant.",
      "isDefault": true
    },
    {
      "locale": "de-de",
      "subject": "Ihr Gerät ist nicht konform",
      "messageTemplate": "Bitte ergreifen Sie Maßnahmen.",
      "isDefault": false
    }
  ]
}
```

## Branding Options

Available branding options for notifications:

| Option | Description |
|--------|-------------|
| `includeCompanyLogo` | Include company logo in the notification |
| `includeCompanyName` | Include company name in the notification |
| `includeContactInformation` | Include IT contact information |
| `includeCompanyPortalLink` | Include link to Company Portal |
| `includeDeviceDetails` | Include device details in the notification |

## Graph API Endpoints

| Operation | Endpoint |
|-----------|----------|
| Templates | `beta/deviceManagement/notificationMessageTemplates` |
| Localized Messages | `beta/deviceManagement/notificationMessageTemplates/{id}/localizedNotificationMessages` |

## Safety Features

- Only deletes templates with "Imported by Intune-Hydration-Kit" in description
- Existing templates with the same name are skipped
- Pre-fetches existing templates to minimize API calls
- Full `-WhatIf` support for dry-run previews

## Related Functions

- [Import-IntuneCompliancePolicy](Import-IntuneCompliancePolicy.md)
